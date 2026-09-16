# Pass 6 — native Monolith PBR material sets

Uses actual prebuilt matched PBR maps extracted from the Monolith native material output rather than the seed procedural vocabulary.

Atlas tiles, left to right:
1. `axiom-dark-frame-aaa`
2. `mir-aged-ivory-aaa`
3. `axiom-pale-ceramic-aaa`

Channels: base color, normal, roughness, metallic.

Verified reconstructed atlas ZIP SHA-256:
`6f8cee3c61416138229a5334c58213fad531b0fe7d9ab40efc667ac93aeb6b10`

CI reconstructs the atlas from small verified text chunks, checks the SHA-256 and ZIP integrity, then imports the maps into Godot.