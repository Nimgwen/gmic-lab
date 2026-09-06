# simple edge detection
gmic "in/sophie original.png" fx_edges 0.015,12.5,1 o out/edges.png

# identify colorspace of img
identify -format "profile: %[profile:icc]\n" "out/Diff_Gauss_Glare.png" 

# difference of gaussians
gmic "in/sophie original.png" dog 0.1,100 o out/edges.png

# pixel sort script
gmic "in/sophie original.png" +norm +ge[-1] 45% +pixelsort[0] +,y,[1],[2] -o out/pixelsort.png

gmic "in/sophie original.png" norm o out/norm.png 

identify -format "%z-bit, range %[min]-%[max]\n" out/norm.png

# pixelsort > edges
gmic "in/sophie original.png" +norm +ge[-1] 45% +pixelsort[0] +,y,[1],[2] +fx_edges[-1] 0.015,12.5,1 o[-1] out/pixelsort.png

# mix with masked out sophie to avoid pixel sorting her face and fingers
# make the graffiti legible by masking it out
# colorize with a glitched background layer and blend modes
# could use FM filter for that

# Get documentation sample images
gmic sample colorful -o out/colorful.png

# colorful is the name of sample image
# use help to get the other names
# sample=sp

# qam glitch
fx_qam_glitch 2.9,29.2,76.32,0,1,127.5,0,1,1,1,0,0,17.59,5,0,0,0,2,0.6,0.05,0,50,50

# Offset Stripes
# examples here https://x.com/gmic_eu/status/1995500417229160451?s=20
# take into account the 2 new parameters Random PDF for vertical/horizontal

awk '/^#@gui Offset Stripes/{f=1} f&&/^#@gui : /{print} f&&/^[a-zA-Z_]+ *:/{exit}' gmic_stdlib.gmic
#Command to extract the arguments of the filter from stdlib source

#Output:
#@gui : Description = note{"<span color="#EE5500"><b>Description:</b></span> \
#@gui : "}, sep = separator()
#@gui : Iterations = ~int(1,0,256)
#@gui : Random Seed = ~int(0,0,65535)
#@gui : Per-Channel Shift = ~bool()
#@gui : sep = separator()
#@gui : note = note("<span color="#EE5500"><small><b>Horizontal Stripes:</b></small></span>")
#@gui : Height (%) = ~float(10,0,100)
#@gui : Random Shift Amplitude (%) = ~float(20,0,100)
#@gui : Random PDF = choice("Gaussian","Uniform")
#@gui : sep = separator()
#@gui : note = note("<span color="#EE5500"><small><b>Vertical Stripes:</b></small></span>")
#@gui : Width (%) = ~float(10,0,100)
#@gui : Random Shift Amplitude (%) = ~float(20,0,100)
#@gui : Random PDF = choice("Gaussian","Uniform")
#@gui : sep = separator()
#@gui : Boundary = ~choice(3,"Transparent","Nearest","Periodic","Mirror")
#@gui : Channel(s) = ~choice("All","RGBA [All]","RGBA [Red-Green-Blue]","RGBA [Red]","RGBA [Green]","RGBA [Blue]",\

gmic sp colorful fx_offset_stripes 50,0,1,2,2,1,2,2,1,3,0 -o "out/offset_stripes.png"
#painting like effect, need more iterarion with higher res images
#at 1000s of iterations it gets too slow (apparently the max on the GUI is 256, but the CLI can go further?)
gmic sp colorful fx_offset_stripes 500,0,1,2,2,1,2,2,1,3,0 -o "out/offset_stripes.png"
#iterations/res ratio determines how diffuse it looks

gmic sp colorful fx_offset_stripes 55,26544,1,73.24,84.96,1,20.55,26.25,1,3,18 -o "out/offset_stripes.png"
#interesting eye distortions at iterions: 13 and 55 +/- 5
#could animate this by interpolating frames with AI or morphing
#Or flickering effects to jump between frames


gmic "in/sophie original.png" fx_offset_stripes 55,26544,1,73.24,84.96,1,20.55,26.25,1,3,18 -o "out/sophie_offset_stripes.png"
gmic "in/sophie original.png" fx_offset_stripes 50,0,1,2,2,1,2,2,1,3,0 -o "out/sophie_offset_stripes.png"

#FM Filter I ported with claude 
awk '/^#@gui FM Glitch/{f=1} f&&/^#@gui : /{print} f&&/^[a-zA-Z_]+ *:/{exit}' nimgwen.gmic

#Arguments:
#@gui : note = note("<b>Carrier</b>")
#@gui : Carrier = float(0.5,0,1)
#@gui : Bandwidth = float(0.5,0,1)
#@gui : Quantization = float(30,0,255)

#@gui : note = note("<b>Colour</b>")
#@gui : Negate = bool(0)
#@gui : Colour Space = choice("RGB","YCbCr","Lab","HSV")
#@gui : First Channel Only = bool(0)

#@gui : note = note("<b>Carrier Removal</b>")
#@gui : Lowpass 1 = bool(1)
#@gui : Lowpass 2 = bool(1)
#@gui : Lowpass 3 = bool(1)

#@gui : Blend With Original = float(0,0,1)

#Modulation example:

gmic sp colorful nim_fm_glitch 0.5,0.5,1.0000000000001 -o out/fm.png
#increase the last parameter starting at 0-1
#to slowly "tune into" the coherent image from blank/noise
#the sweet spot varies with the first 2 parameters
#experiment by adding decimals to find

#Example with 0.5,0.5 the sweet spot is between:
#1.0000000000001 = image is mostly blank/grey
gmic sp colorful nim_fm_glitch 0.5,0.5,1.0000000000001 -o out/fm.png
#increase until 1.001 to slowly build noise up
gmic sp colorful nim_fm_glitch 0.5,0.5,1.001 -o out/fm.png
#at 1.01 the face becomes intelligible
#So from 1.001 to 1.01 slowly fades in the face from the noise
gmic sp colorful nim_fm_glitch 0.5,0.5,1.002 -o out/fm.png
gmic sp colorful nim_fm_glitch 0.5,0.5,1.005 -o out/fm.png
gmic sp colorful nim_fm_glitch 0.5,0.5,1.01 -o out/fm.png
gmic sp colorful nim_fm_glitch 0.5,0.5,1.1 -o out/fm.png
#at 10 the faces becomes fully defined
gmic sp colorful nim_fm_glitch 0.5,0.5,10 -o out/fm.png
#further increases don't change much anymore
gmic sp colorful nim_fm_glitch 0.5,0.5,1000 -o out/fm.png


gmic sp colorful,1600,1600 nim_fm_glitch 0.5,0.5,1000 -o out/fm_big.png
#higher resolution just makes it sharper, lower softer/more diffuse

gmic sp peppers,1600,1600 nim_fm_glitch 0.5,0.5,10 negate fx_blur_bloom_glare 1,4,5,1,2,0,1,1,5,0.5,0,0 -o out/bottles.png