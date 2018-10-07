
.section .rodata
.global _sample
.balign 16
_sample:

#ifdef _SAMPLE_CAT
.incbin "../resources/cat.raw"
#endif

#ifdef _SAMPLE_GUITAR
.incbin "../resources/guitar.raw"
#endif

#ifdef _SAMPLE_PIANO
.incbin "../resources/piano.raw"
#endif


.global _sample_size
.align 4
_sample_size:
.int (_sample_size - _sample) / 2


