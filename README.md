# ares
Finding areas of convex polygon masks (star domains) in images.

## How to use
The program requires two inputs. The first one is the actual image mask where the part we want to find the area of is coloured in black.
![White image with black, convex and connected polygon](https://raw.githubusercontent.com/SV-97/ares/main/arej/in.bmp)

The second one is a normalization image with a black square of sidelength 1mm in the same resolution as the mask.
![White image with black square](https://raw.githubusercontent.com/SV-97/ares/main/arej/norm.bmp)

This input will produce some images telling you the inferred edges and polygon-vertices
![Rough outline of input polygon and second image where only the vertices are marked](https://raw.githubusercontent.com/SV-97/ares/main/arej/Output.png)
as well as the following text
```
The area is 21.140775034293583 mm². ~27 pixels are 1 mm.
Press any button to continue...
```

## Internals
Internally this program roughly works as follows:
* Find the rough (non-horizontal) edges of the polygon by superimposing multiple copies on top of each other. We only consider non-horizontal edges because we can trivially reconstruct horizontal ones from that.
* Using a [Graham Scan](https://en.wikipedia.org/wiki/Graham_scan) we find the convex hull of the points we got before.
* Clean up the edges by running linear interpolations on successively longer point-trails on the hull such that a configurable error isn't exceeded.
* Decompose the polygon into triangles to calculate the total area in pixels.
* Change units to millimeters.

An interesting alternative algorithm would be to use [Pick's Theorem](https://en.wikipedia.org/wiki/Pick%27s_theorem) or simple pixel counting.
