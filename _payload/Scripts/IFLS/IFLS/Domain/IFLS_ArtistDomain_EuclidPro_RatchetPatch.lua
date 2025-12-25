-- PATCH-HINWEIS:
-- In IFLS_ArtistDomain.apply_euclidpro_defaults_from_preset(preset)
-- nach den bisherigen Core-Feldern können optional noch Ratchet-Defaults
-- gesetzt werden:

  setnum("RATCHET_PROB", cfg.ratchet_prob)
  setnum("RATCHET_MIN",  cfg.ratchet_min)
  setnum("RATCHET_MAX",  cfg.ratchet_max)
  setstr("RATCHET_SHAPE", cfg.ratchet_shape)

-- Wenn ein Artist-Preset diese Felder in default_euclidpro mitliefert,
-- werden sie automatisch in IFLS_EUCLIDPRO geschrieben.
