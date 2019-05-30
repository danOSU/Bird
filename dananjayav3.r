library('warbleR')
# Create a new directory
dir.create(file.path(getwd(),"dananjaya"))
setwd(file.path(getwd(),"dananjaya"))

pause = function()
{
    if (interactive())
    {
        invisible(readline(prompt = "Press <Enter> to continue..."))
    }
    else
    {
        cat("Press <Enter> to continue...")
        invisible(readLines(file("stdin"), 1))
    }
}

# Query Xeno-Canto for all recordings birds in USA
#USA <- querxc('cnt:"United States"', download = FALSE) 
#names(USA)
#View(USA)
print("# Query Xeno-Canto for all recordings of the species Phaethornis longirostris")
USA.Texas.A <- querxc('cnt:"United States" loc: "Texas" q: A', download = FALSE) 
print("#view command output")
#View(USA.Texas.A)
print("# Find out number of available recordings")
nrow(USA.Texas.A) 
print("# Find out how many types of signal descriptions exist in the Xeno-Canto metadata")
levels(USA.Texas.A$Vocalization_type)

print("How many recordings per signal type?")
#table(USA.Texas.A$Vocalization_type)

# There are many levels to the Vocalization_type variable. 
# Some are biologically relevant signals, but most just 
# reflect variation in data entry.

print("# Luckily, it's very easy to filter the signals we want,filter only songs") 
usata.song <- droplevels(USA.Texas.A[grep("song", USA.Texas.A$Vocalization_type, ignore.case = TRUE), ])

print("# Check resulting data frame")
str(usata.song) 

print("# Now, how many recordings per locality")
#table(usata.song$Locality)

#first filter by location
#Phae.lon.LS <- Phae.lon.song[grep("La Selva Biological Station, Sarapiqui, Heredia", Phae.lon.song$Locality,ignore.case = FALSE),]

# And only those of the highest quality
#Phae.lon.LS <- Phae.lon.LS[Phae.lon.LS$Quality == "A", ]

#print("generating map # map in the graphic device (img = FALSE)")
#xcmaps(usata.song, img = TRUE)

print("# Loop starts and downnload file by file")
for(song in 8:length(usata.song)){
querxc(X =usata.song[song,]) 

# Save each data frame object as a .csv file 
write.csv(usata.song, "USA_Texas_A.csv", row.names = FALSE)



# Neither of these functions requires arguments
# Always check you're in the right directory beforehand
print(getwd())
mp32wav() 

# You can use checkwavs to see if wav files can be read
checkwavs() 

print("# Let's create a list of all the recordings in the directory")
wavs <- list.files(pattern="wav$")

print("# We will use this list to downsample the wav files so the following analyses go a bit faster")
lapply(wavs, function(x) writeWave(downsample(readWave(x), samp.rate = 22050),filename = x))

# Let's first create a subset for playing with arguments 
print("# This subset is based on the list of wav files we created above,after I changed the code wav has only one file name")
sub <- wavs

# ovlp = 10 speeds up process a bit 
# tiff image files are better quality and are faster to produce
#lspec(flist = sub, ovlp = 10, it = "tiff")

# We can zoom in on the frequency axis by changing flim, 
# the number of seconds per row, and number of rows
#lspec(flist = sub, flim = c(1.5, 11), sxrow = 6, rows = 15, ovlp = 10, it = "tiff")

#lspec(flim = c(1.5, 11), ovlp = 10, sxrow = 6, rows = 15, it = "tiff")

#print("# List the image files in the directory")
# Change the pattern to "jpeg" if you used that image type
#imgs <- list.files(pattern = ".tiff") 

# If the maps we created previously are still there, you can remove them from this list easily
#imgs <- imgs[grep("Map", imgs, invert = TRUE)]

# Extract the recording IDs of the files for which image files remain 
#kept <- unique(sapply(imgs, function(x){
#  strsplit(x, split = "-", fixed = TRUE)[[1]][3]
 # }, USE.NAMES = FALSE))

# Now we can get rid of sound files that do not have image files 
#snds <- list.files(pattern = ".wav", ignore.case = TRUE) 
#file.remove(snds[grep(paste(kept, collapse = "|"), snds, invert = TRUE)])

# Select a subset of the recordings
#wavs <- list.files(pattern = ".wav", ignore.case = TRUE)

# Set a seed so we all have the same results
set.seed(1)
#sub <- wavs[sample(1:length(wavs), 3)]

# Run autodetec() on subset of recordings

#autodetec(flist = sub, bp = c(2, 9), threshold = 20, mindur = 0.09, maxdur = 0.22, 
#                     envt = "abs", ssmooth = 900, ls = TRUE, res = 100, 
#                     flim= c(1, 12), wl = 300, set =TRUE, sxrow = 6, rows = 15, 
#                     redo = TRUE, it = "tiff", img = TRUE)

usa.ad <- autodetec(bp = c(2, 9), threshold = 20, mindur = 0.09, maxdur = 0.22, 
                     envt = "abs", ssmooth = 900, ls = TRUE, res = 100, 
                     flim= c(1, 12), wl = 300, set =TRUE, sxrow = 6, rows = 15, 
                     redo = TRUE, it = "jpeg", img = TRUE)
print("show output of autodetec")
str(usa.ad)

#table(usa.ad$sound.files)

# A margin that's too large causes other signals to be included in the noise measurement
# Re-initialize X as needed, for either autodetec or manualoc output

# Let's try it on 10% of the selections so it goes a faster
# Set a seed first, so we all have the same results
set.seed(5)

#X <- usa.ad[sample(1:nrow(usa.ad),(nrow(usa.ad)*0.1)), ]

#snrspecs(X = X, flim = c(2, 110), snrmar = 0.5, mar = 0.7, it = "tiff")

# This smaller margin is better
#snrspecs(X = X, flim = c(2, 11), snrmar = 0.2, mar = 0.7, it = "tiff")

#snrspecs(X = Phae.ad, flim = c(2, 11), snrmar = 0.2, mar = 0.7, it = "tiff")

usa.snr <- sig2noise(X = usa.ad[seq(1, nrow(usa.ad)), ], mar = 0.04)
print(ave(-usa.snr$SNR, usa.snr$sound.files, FUN = rank))
table(usa.snr)
pause()

usa.hisnr <- usa.snr[ave(-usa.snr$SNR, usa.snr$sound.files, FUN = rank) <= 5, ]

print("# Double check the number of selection per sound files") 
#table(usa.hisnr$sound.files)

write.csv(usa.hisnr, "USA_Texas_A_autodetec_selecs.csv", row.names = FALSE)

# Note that the dominant frequency measurements are almost always more accurate
#trackfreqs(usa.hisnr, flim = c(1, 11), bp = c(1, 12), it = "tiff")

# We can change the lower end of bandpass to make the frequency measurements more precise
#trackfreqs(usa.hisnr, flim = c(1, 11), bp = c(2, 12), col = c("purple", "orange"),
#           pch = c(17, 3), res = 300, it = "tiff")

# If the frequency measurements look acceptable with this bandpass setting,
# that's the setting we should use when running specan() 

# Use the bandpass filter to your advantage, to filter out low or high background
# noise before performing measurements
# The amplitude threshold will change the amplitude at which noises are
# detected for measurements 
params <- specan(usa.hisnr, bp = c(1, 11), threshold = 15)

View(params)

str(params)

write.csv(params, "feature_vector.csv", row.names = FALSE,append= TRUE)
pause()
unlink("*.mp3")
unlink("*.wav")
}
# As always, it's a good idea to write .csv files to your working directory


