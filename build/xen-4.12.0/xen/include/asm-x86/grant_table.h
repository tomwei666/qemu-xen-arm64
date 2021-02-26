/******************************************************************************
 * include/asm-x86/grant_table.h
 *
 * Copyright (c) 2004-2005 K A Fraser
 */

#ifndef __ASM_GRANT_TABLE_H__
#define __ASM_GRANT_TABLE_H__

#include <asm/paging.h>

#include <asm/hvm/grant_table.h>
#include <asm/pv/grant_table.h>

#define INITIAL_NR_GRANT_FRAMES 1U

struct grant_table_arch {
};

/*
 * Caller must own caller's BIGLOCK, is responsible for flushing the TLB, and
 * must hold a reference to the page.
 */
static inline int create_grant_host_mapping(uint64_t addr, mfn_t frame,
                                            unsigned int flags,
                                            unsigned int cache_flags)
{
    if ( paging_mode_external(current->domain) )
        return create_grant_p2m_mapping(addr, frame, flags, cache_flags);
    return create_grant_pv_mapping(addr, frame, flags, cache_flags);
}

static inline int replace_grant_host_mapping(uint64_t addr, mfn_t frame,
                                             uint64_t new_addr,
                                             unsigned int flags)
{
    if ( paging_mode_external(current->domain) )
        return replace_grant_p2m_mapping(addr, frame, new_addr, flags);
    return replace_grant_pv_mapping(addr, frame, new_addr, flags);
}

#define gnttab_init_arch(gt) 0
#define gnttab_destroy_arch(gt) do {} while ( 0 )
#define gnttab_set_frame_gfn(gt, st, idx, gfn) do {} while ( 0 )
#define gnttab_get_frame_gfn(gt, st, idx) ({                             \
    unsigned long mfn_ = (st) ? gnttab_status_mfn(gt, idx)               \
                              : gnttab_shared_mfn(gt, idx);              \
    unsigned long gpfn_ = get_gpfn_from_mfn(mfn_);                       \
    VALID_M2P(gpfn_) ? _gfn(gpfn_) : INVALID_GFN;                        \
})

#define gnttab_shared_mfn(t, i)                         \
    ((virt_to_maddr((t)->shared_raw[i]) >> PAGE_SHIFT))

#define gnttab_shared_gmfn(d, t, i)                     \
    (mfn_to_gmfn(d, gnttab_shared_mfn(t, i)))


#define gnttab_status_mfn(t, i)                         \
    ((virt_to_maddr((t)->status[i]) >> PAGE_SHIFT))

#define gnttab_status_gmfn(d, t, i)                     \
    (mfn_to_gmfn(d, gnttab_status_mfn(t, i)))

#define gnttab_mark_dirty(d, f) paging_mark_dirty((d), f)

static inline void gnttab_clear_flag(unsigned int nr, uint16_t *st)
{
    /*
     * Note that this cannot be clear_bit(), as the access must be
     * confined to the specified 2 bytes.
     */
    asm volatile ("lock btrw %w1,%0" : "=m" (*st) : "Ir" (nr), "m" (*st));
}

/* Foreign mappings of HHVM-guest pages do not modify the type count. */
#define gnttab_host_mapping_get_page_type(ro, ld, rd)   \
    (!(ro) && (((ld) == (rd)) || !paging_mode_external(rd)))

/* Done implicitly when page tables are destroyed. */
#define gnttab_release_host_mappings(domain) ( paging_mode_external(domain) )

#define gnttab_need_iommu_mapping(d)                \
    (!paging_mode_translate(d) && need_iommu_pt_sync(d))

#endif /* __ASM_GRANT_TABLE_H__ */
