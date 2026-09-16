# Pass 5 — AXM Material Surface Fabric bridge

Pass 5 ports the proven deterministic material-family logic from the Monolith's `axm-material-surface-fabric` v0.18.6 / material vocabulary v0.7 into the Godot runtime overlay.

The store now generates correlated base-color, normal, roughness, metallic and ambient-occlusion maps for selected AXM material families at runtime, including brushed steel, painted steel, oak, concrete, granite, asphalt and hard plastic. The metal surfaces also reuse the fabric's grime and fine-scratch overlay concepts. This remains synthetic material evidence, not scanned or physically certified PBR data.
