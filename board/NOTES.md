v2 issues:
- RX/TX to usb-serial chip inverted

v2 notes:
- "wrong" footprint for display
  - used the "connector" footprint but soldered...
  - should've used the solderable pinout (wider) or a connector..
- audio:
  - using resistor instead of voltage divider
  - shoddy audio idea of soldering pcb on pcb
  - direct soldering MAX98357 SKETCH
  - volume control (potentiometer) too far from edge
  - volume control footprint loose, no metal on mechanical holes
- testpoints very small
- labels very small
- battery JST different
- usb-micro not usb-c
- "jumpers" for display fuckups:
    - too close (side-by-side)
	- too large footprint for easy bridging? (MB)
- BUY STENCIL
