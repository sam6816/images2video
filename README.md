# images2video

Download images from Eumetsat website and directly create a video like this
<a href=https://youtu.be/zUIGst0qVF8>youtu.be/zUIGst0qVF8</a> sample.

This is a combination of a curl download of a list of files and 
ffmpeg's image2pipe format. No image files have to be stored locally.

The script itself is thus called "eumet.sh". The main thing it does is generate
a list of the current hourly images since a certain date. Eumetsat keeps about
115 images around, the last 5 days. So by using this script every 4-5 days you
can record without gaps or overlappings.

There is too much to modify or tune; there are some params, but mostly it is meant
to be changed in the dot script, and to be re-sourced.

There is low- and hi-res, 800 vs. 3712 pixels square. I used hi-res for the 
1080x1080 animation, but the difference on my Full HD screen is small. A minimum is 
maybe 500x500, good if you want to keep the mp4 small. 


### ffmpeg options

With the hi-res, the `-s` option in ffmpeg is important; otherwise it will try/make a 
3712x3712 video. 
 
ffmpeg needs `-pix_fmt` because the images are in an old JFIF format with `yuvj420p`; 
this works, but ffplay gives a warning for each frame.

I also left the `-c hevc` because the mp4 is almost half the size than with h264. 
Firefox says "corrupt", but for ffplay and youtube it is OK.


































