# Download Eumetsat images according to a generated list directly into ffmpeg image2pipe

# Host and path(s)
h=eumetview.eumetsat.int
p=static-images/MSG/RGB/AIRMASS/
p+=FULLDISC  
#FULLRESOLUTION is 3000x3000 (vs. 800x800) but hardly a difference at scaled-down size; takes long unscaled 

# Japanese: https://www.data.jma.go.jp/mscweb/data/himawari/list_fd_.html
# I only find one day/24 with 10min intervals...

# Default filenames
index=eumetindex.html
imagelist=eumetimages
ffout=eumet.mp4

all-eumet() {
    curl-eu $index 
    sed-eu $1 $2 $3 $4 
    imagepipe $imagelist $ffout
}

#params dd mm yy hh 
sed-eu() {

    # get value/num of the given date, 0-115 
    # <option value="0">11/11/22   14:00 UTC</option>
    num=$(sed -nE "s/.*option value=\"([0-9]*)\">$1\/$2\/$3\s*$4:00.*/\1/p"  $index)

    # Sanity check for single integer --sigh--
    case $num in 
        "" ) 
            echo "Empty num (no match for given date $1 $2 $3 $4 found)"; return;;
        *[![:digit:]]* )  
            echo "Non-digit (several matches?!?) in num=\"$num\""; return;;
    esac

    echo "Found date $1/$2/$3 $4:00 plus $num newer ones"

    # extract filename from latest to num-th older line 
    # array_nom_imagen[0]="f9ku3Ijq5hgZo"
    sed -nE "/imagen\[0\]/,+$num s/.*=\"(\w*)\"/\1/p"  $index > $imagelist
}

curl-eu() {
    local out=${1:-$index} 
    curl https://$h/$p/ -o $out 
}

# curl keeps file order, wget not! wget has -i/-B options, curl wants comma sep. list
# tac for ascending chronology (old at top)
imagepipe() {

    curl-images $1 "pipe"  |
    ffmpeg -f image2pipe -i - -pix_fmt yuv444p -y $2
}

# into pipe or a dir with original names
curl-images() {
    
    local csv=$(tac $1 | paste -sd,)
    local out
    if [[ $2 == "pipe" ]]
    then 
       out=""
    else 
       out="-O --output-dir $2"
    fi        
    local pimag=IMAGESDisplay

    # quote braces, but not $out (several args!)!
    curl https://$h/$p/$pimag/"{$csv}" $out  
}

ffconcat() {
    ffmpeg -f concat -i $1 -c:v copy newconcat.mp4
}
