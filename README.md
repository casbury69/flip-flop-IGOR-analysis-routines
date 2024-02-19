This software is used by my laboratory to analyze data from our "flip-flop" experiments.  In these experiments, individual kinetochores are first assembled de novo from cell extracts onto single centromeric DNA molecules.  After washing away the extract, fluorescent stabilized microtbubules are introduced and captured by the surface-tethered kinetochores, which carry GFP fused to a selected subcomponent.  A gentle flow of buffer is applied to orient the kinetochores and their attached microtubules downstream in the flow, while they are viewed in a total internal reflection fluorescence (TIRF) microscope.  The flow is oscillated back-and-forth, so the microtubules and kinetochores periodicially re-orient with each reversal of the direction of flow.  We use an imageJ plugin, the MOSAICsuite 2D particle tracker (https://imagej.net/plugins/mosaicsuite), to generate records of position-vs-time from the TIRF recordings.

The software provided here opens the MOSAICsuite output files, and facilitates user-selection of intervals during which the microtubule was stably oriented in the flow, and then automatically measures the displacement of the fluorescent-tagged kinetochore component during the user-selected intervals.

The software is written for IGOR Pro.

The software provided here is adapted specifically for the instruments I have built in my laboratory at the University of Washington. We currently run it in IGOR Pro 9. It is open source, licensed under the MIT License. I do not provide extensive documentation for it here, but would be happy to consult with anyone who wishes to adapt it for their own use.

Author: Chip Asbury; Department of Physiology & Biophysics; University of Washington School of Medicine; Seattle, WA 98195; casbury@uw.edu
