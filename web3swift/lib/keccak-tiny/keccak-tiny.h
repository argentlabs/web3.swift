#ifndef KECCAK_FIPS202_H
#define KECCAK_FIPS202_H
#define __STDC_WANT_LIB_EXT1__ 1
#include <stdint.h>
#include <stdlib.h>

#define decshake(bits) \
  int shake##bits(uint8_t*, size_t, const uint8_t*, size_t);

#define deckeccak(bits) \
  int keccak_##bits(uint8_t*, size_t, const uint8_t*, size_t);

decshake(128)
decshake(256)
deckeccak(224)
deckeccak(256)
deckeccak(384)
deckeccak(512)
#endif
