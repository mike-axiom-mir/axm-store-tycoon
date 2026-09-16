# Pass 6 — native Monolith PBR material sets

Uses actual prebuilt matched PBR maps extracted from the Monolith native material output rather than the seed procedural vocabulary.

Atlas tiles, left to right:
1. `axiom-dark-frame-aaa`
2. `mir-aged-ivory-aaa`
3. `axiom-pale-ceramic-aaa`

Channels: base color, normal, roughness, metallic. CI reconstructs the small native-map ZIP from chunked base64 text before Godot imports the project.