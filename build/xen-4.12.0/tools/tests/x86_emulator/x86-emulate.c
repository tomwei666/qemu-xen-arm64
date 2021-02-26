#include "x86-emulate.h"

#include <sys/mman.h>

#define cpu_has_amd_erratum(nr) 0
#define cpu_has_mpx false
#define read_bndcfgu() 0
#define xstate_set_init(what)

/* For generic assembly code: use macros to define operation/operand sizes. */
#ifdef __i386__
# define r(name)       e ## name
# define __OS          "l"  /* Operation Suffix */
# define __OP          "e"  /* Operand Prefix */
#else
# define r(name)       r ## name
# define __OS          "q"  /* Operation Suffix */
# define __OP          "r"  /* Operand Prefix */
#endif

#define get_stub(stb) ({                         \
    assert(!(stb).addr);                         \
    (void *)((stb).addr = (uintptr_t)(stb).buf); \
})
#define put_stub(stb) ((stb).addr = 0)

uint32_t mxcsr_mask = 0x0000ffbf;
struct cpuid_policy cp;

static char fpu_save_area[4096] __attribute__((__aligned__((64))));
static bool use_xsave;

void emul_save_fpu_state(void)
{
    if ( use_xsave )
        asm volatile ( "xsave %[ptr]"
                       : [ptr] "=m" (fpu_save_area)
                       : "a" (~0ul), "d" (~0ul) );
    else
        asm volatile ( "fxsave %0" : "=m" (fpu_save_area) );
}

void emul_restore_fpu_state(void)
{
    /* Older gcc can't deal with "m" array inputs; make them outputs instead. */
    if ( use_xsave )
        asm volatile ( "xrstor %[ptr]"
                       : [ptr] "+m" (fpu_save_area)
                       : "a" (~0ul), "d" (~0ul) );
    else
        asm volatile ( "fxrstor %0" : "+m" (fpu_save_area) );
}

bool emul_test_init(void)
{
    union {
        char x[464];
        struct {
            uint32_t other[6];
            uint32_t mxcsr;
            uint32_t mxcsr_mask;
            /* ... */
        };
    } *fxs = (void *)fpu_save_area;

    unsigned long sp;

    x86_cpuid_policy_fill_native(&cp);

    /*
     * The emulator doesn't use these instructions, so can always emulate
     * them.
     */
    cp.basic.movbe = true;
    cp.feat.adx = true;
    cp.feat.rdpid = true;
    cp.extd.clzero = true;

    if ( cpu_has_xsave )
    {
        unsigned int tmp, ebx;

        asm ( "cpuid"
              : "=a" (tmp), "=b" (ebx), "=c" (tmp), "=d" (tmp)
              : "a" (0xd), "c" (0) );

        /*
         * Sanity check that fpu_save_area[] is large enough.  This assertion
         * will trip eventually, at which point fpu_save_area[] needs to get
         * larger.
         */
        assert(ebx < sizeof(fpu_save_area));

        /* Use xsave if available... */
        use_xsave = true;
    }
    else
        /* But use fxsave if xsave isn't available. */
        assert(cpu_has_fxsr);

    /* Reuse the save state buffer to find mcxsr_mask. */
    asm ( "fxsave %0" : "=m" (*fxs) );
    if ( fxs->mxcsr_mask )
        mxcsr_mask = fxs->mxcsr_mask;

    /*
     * Mark the entire stack executable so that the stub executions
     * don't fault
     */
#ifdef __x86_64__
    asm ("movq %%rsp, %0" : "=g" (sp));
#else
    asm ("movl %%esp, %0" : "=g" (sp));
#endif

    return mprotect((void *)(sp & -0x1000L) - (MMAP_SZ - 0x1000),
                    MMAP_SZ, PROT_READ|PROT_WRITE|PROT_EXEC) == 0;
}

int emul_test_cpuid(
    uint32_t leaf,
    uint32_t subleaf,
    struct cpuid_leaf *res,
    struct x86_emulate_ctxt *ctxt)
{
    asm ("cpuid"
         : "=a" (res->a), "=b" (res->b), "=c" (res->c), "=d" (res->d)
         : "a" (leaf), "c" (subleaf));

    /*
     * The emulator doesn't itself use MOVBE, so we can always run the
     * respective tests.
     */
    if ( leaf == 1 )
        res->c |= 1U << 22;

    /*
     * The emulator doesn't itself use ADCX/ADOX/RDPID, so we can always run
     * the respective tests.
     */
    if ( leaf == 7 && subleaf == 0 )
    {
        res->b |= 1U << 19;
        res->c |= 1U << 22;
    }

    /*
     * The emulator doesn't itself use CLZERO, so we can always run the
     * respective test(s).
     */
    if ( leaf == 0x80000008 )
        res->b |= 1U << 0;

    return X86EMUL_OKAY;
}

int emul_test_read_cr(
    unsigned int reg,
    unsigned long *val,
    struct x86_emulate_ctxt *ctxt)
{
    /* Fake just enough state for the emulator's _get_fpu() to be happy. */
    switch ( reg )
    {
    case 0:
        *val = 0x00000001; /* PE */
        return X86EMUL_OKAY;

    case 4:
        /* OSFXSR, OSXMMEXCPT, and maybe OSXSAVE */
        *val = 0x00000600 | (cpu_has_xsave ? 0x00040000 : 0);
        return X86EMUL_OKAY;
    }

    return X86EMUL_UNHANDLEABLE;
}

int emul_test_read_xcr(
    unsigned int reg,
    uint64_t *val,
    struct x86_emulate_ctxt *ctxt)
{
    uint32_t lo, hi;

    ASSERT(cpu_has_xsave);

    switch ( reg )
    {
    case 0:
        break;

    case 1:
        if ( cpu_has_xgetbv1 )
            break;
        /* fall through */
    default:
        x86_emul_hw_exception(13 /* #GP */, 0, ctxt);
        return X86EMUL_EXCEPTION;
    }

    asm ( "xgetbv" : "=a" (lo), "=d" (hi) : "c" (reg) );
    *val = lo | ((uint64_t)hi << 32);

    return X86EMUL_OKAY;
}

int emul_test_get_fpu(
    enum x86_emulate_fpu_type type,
    struct x86_emulate_ctxt *ctxt)
{
    switch ( type )
    {
    case X86EMUL_FPU_fpu:
        break;
    case X86EMUL_FPU_mmx:
        if ( cpu_has_mmx )
            break;
    case X86EMUL_FPU_xmm:
        if ( cpu_has_sse )
            break;
    case X86EMUL_FPU_ymm:
        if ( cpu_has_avx )
            break;
    case X86EMUL_FPU_opmask:
    case X86EMUL_FPU_zmm:
        if ( cpu_has_avx512f )
            break;
    default:
        return X86EMUL_UNHANDLEABLE;
    }
    return X86EMUL_OKAY;
}

void emul_test_put_fpu(
    struct x86_emulate_ctxt *ctxt,
    enum x86_emulate_fpu_type backout,
    const struct x86_emul_fpu_aux *aux)
{
    /* TBD */
}

#include "x86_emulate/x86_emulate.c"
