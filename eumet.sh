# Download Eumetsat images according to a generated list directly into ffmpeg image2pipe format
# all_eumet dd mm yy hh 
# ...to create a mp4 file directly. But the functions can all be used separately. 
# The steps are: curl the index, with sed search for the date and write the imagelist, then curl the images into ffmpeg (or a dir)

eumet_vars() {
    h=eumetview.eumetsat.int
    p=static-images/MSG/RGB/AIRMASS/
    # Two resolutions; choose here:
    p+=FULLDISC         # 800px square
    # p+=FULLRESOLUTION # 3712px square

    # Default filenames
    index=eumetindex.html imagelist=eumetimages ffout=eumet.mp4
}
# wrapping function
all_eumet() {
    eumet_vars
    curl https://$h/$p/ -o $index 
    sed_eumet $1 $2 $3 $4 $index $imagelist 
    imagepipe $imagelist $ffout
}
# Generate imagelist by date from eumetsat index.htm which has a <select> date menu and an image name array:
#       <option value="0">11/11/22   14:00 UTC</option>   
#       array_nom_imagen[0]="f9ku3Ijq5hgZo"
# above "0" is the first 'value'/image index
# looks like javascript uses selectedIndex, but the numbers are reliable, even when some images/dates are missing
sed_eumet() {
    local dd=$1 mm=$2 yy=$3 hh=$4
    local fin=${5:-$index} fout=${6:-$imagelist}

    # get value/num of the given date, 0-115 
    local num=$(sed -nE "s/.*option value=\"([0-9]*)\">$dd\/$mm\/$yy\s*$hh:00.*/\1/p" $fin)

    if [[ -z $num ]]
        then echo "empty \$num meaning no match found"; return; fi 
    # sanity check for non-digit
    if [[ $num =~ [^[:digit:]] ]] 
        then echo "non-digit inside" $num; return; fi 
        
    echo "Found one date $dd/$mm/$yy $hh:00 plus $num newer ones reading from $fin"
    echo "Writing to $fout"
 
    # extract filename from latest to num-th older line (down)
    sed -nE "/imagen\[0\]/,+$num s/.*=\"(\w*)\"/\1/p"  $fin > $fout
}
# curl keeps file order when piping, wget not! wget has nice i/B options, curl wants csv 
# tac for ascending chronology (old at top)
# either into pipe or into a dir, with original names, which on eumetsat are random (but in the right order)
# IMAGESDisplay is hardcoded, and $h and $p are global
multicurl() {
    local csv=$(tac $1 | paste -sd,) dir=$2 
    if [[ -n $dir ]]
        then dir="-O --output-dir $2"
    fi
    curl https://$h/$p/IMAGESDisplay/"{$csv}" $dir  
}
# Combine download from a list and ffmpeg
imagepipe() {
    
    multicurl $1 |
    ffmpeg -f image2pipe -i - -pix_fmt yuv420p -s 1080x1080 -c hevc -y $2
}
# no transcoding needed, then just copy
ffconcat() {
    ffmpeg -f concat -i $1 -c:v copy newconcat.mp4
}
eumet_unset() {
    unset h p index imagelist ffout
    unset eumet_vars eumet_unset
    unset all_eumet sed_eumet multicurl imagepipe ffconcat 
}
