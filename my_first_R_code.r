library('warbleR')
# Create a new directory
dir.create(file.path(getwd(),"warbleR_example"))
setwd(file.path(getwd(),"warbleR_example"))

# Query Xeno-Canto for all recordings of the hummingbird genus Phaethornis
Phae <- querxc(qword = "Phaethornis", download = FALSE) 
names(Phae)
#View(Phae)
# Query Xeno-Canto for all recordings of the species Phaethornis longirostris
Phae.lon <- querxc(qword = "Phaethornis longirostris", download = FALSE) 
View(Phae.lon)
# Find out number of available recordings
nrow(Phae.lon) 
# Find out how many types of signal descriptions exist in the Xeno-Canto metadata
levels(Phae.lon$Vocalization_type)

# How many recordings per signal type?
table(Phae.lon$Vocalization_type)

# There are many levels to the Vocalization_type variable. 
# Some are biologically relevant signals, but most just 
# reflect variation in data entry.

# Luckily, it's very easy to filter the signals we want 
Phae.lon.song <- droplevels(Phae.lon[grep("song", Phae.lon$Vocalization_type, ignore.case = TRUE), ])

# Check resulting data frame
str(Phae.lon.song) 

# Now, how many recordings per locatity?
table(Phae.lon.song$Locality)

#first filter by location
Phae.lon.LS <- Phae.lon.song[grep("La Selva Biological Station, Sarapiqui, Heredia", Phae.lon.song$Locality,ignore.case = FALSE),]

# And only those of the highest quality
Phae.lon.LS <- Phae.lon.LS[Phae.lon.LS$Quality == "A", ]

# map in the graphic device (img = FALSE)
xcmaps(Phae.lon.LS, img = TRUE)

# Download sound files
querxc(X = Phae.lon.LS) 

# Save each data frame object as a .csv file 
write.csv(Phae.lon.LS, "Phae_lon.LS.csv", row.names = FALSE)



# Neither of these functions requires arguments
# Always check you're in the right directory beforehand
# getwd()
mp32wav() 

# You can use checkwavs to see if wav files can be read
checkwavs() 

# Let's create a list of all the recordings in the directory
wavs <- list.files(pattern="wav$")

# We will use this list to downsample the wav files so the following analyses go a bit faster
lapply(wavs, function(x) writeWave(downsample(readWave(x), samp.rate = 22050),filename = x))

# Let's first create a subset for playing with arguments 
# This subset is based on the list of wav files we created above
sub <- wavs[c(1,3)]

# ovlp = 10 speeds up process a bit 
# tiff image files are better quality and are faster to produce
lspec(flist = sub, ovlp = 10, it = "tiff")

# We can zoom in on the frequency axis by changing flim, 
# the number of seconds per row, and number of rows
lspec(flist = sub, flim = c(1.5, 11), sxrow = 6, rows = 15, ovlp = 10, it = "tiff")

lspec(flim = c(1.5, 11), ovlp = 10, sxrow = 6, rows = 15, it = "tiff")

# List the image files in the directory
# Change the pattern to "jpeg" if you used that image type
imgs <- list.files(pattern = ".tiff") 

# If the maps we created previously are still there, you can remove them from this list easily
imgs <- imgs[grep("Map", imgs, invert = TRUE)]

# Extract the recording IDs of the files for which image files remain 
kept <- unique(sapply(imgs, function(x){
  strsplit(x, split = "-", fixed = TRUE)[[1]][3]
  }, USE.NAMES = FALSE))

# Now we can get rid of sound files that do not have image files 
snds <- list.files(pattern = ".wav", ignore.case = TRUE) 
file.remove(snds[grep(paste(kept, collapse = "|"), snds, invert = TRUE)])

# Select a subset of the recordings
wavs <- list.files(pattern = ".wav", ignore.case = TRUE)

# Set a seed so we all have the same results
set.seed(1)
sub <- wavs[sample(1:length(wavs), 3)]

# Run autodetec() on subset of recordings

autodetec(flist = sub, bp = c(2, 9), threshold = 20, mindur = 0.09, maxdur = 0.22, 
                     envt = "abs", ssmooth = 900, ls = TRUE, res = 100, 
                     flim= c(1, 12), wl = 300, set =TRUE, sxrow = 6, rows = 15, 
                     redo = TRUE, it = "tiff", img = TRUE)

Phae.ad <- autodetec(bp = c(2, 9), threshold = 20, mindur = 0.09, maxdur = 0.22, 
                     envt = "abs", ssmooth = 900, ls = TRUE, res = 100, 
                     flim= c(1, 12), wl = 300, set =TRUE, sxrow = 6, rows = 15, 
                     redo = TRUE, it = "tiff", img = TRUE)

str(Phae.ad)

table(Phae.ad$sound.files)

# A margin that's too large causes other signals to be included in the noise measurement
# Re-initialize X as needed, for either autodetec or manualoc output

# Let's try it on 10% of the selections so it goes a faster
# Set a seed first, so we all have the same results
set.seed(5)

X <- Phae.ad[sample(1:nrow(Phae.ad),(nrow(Phae.ad)*0.1)), ]

snrspecs(X = X, flim = c(2, 110), snrmar = 0.5, mar = 0.7, it = "tiff")

# This smaller margin is better
snrspecs(X = X, flim = c(2, 11), snrmar = 0.2, mar = 0.7, it = "tiff")

snrspecs(X = Phae.ad, flim = c(2, 11), snrmar = 0.2, mar = 0.7, it = "tiff")

Phae.snr <- sig2noise(X = Phae.ad[seq(1, nrow(Phae.ad), 2), ], mar = 0.04)

Phae.hisnr <- Phae.snr[ave(-Phae.snr$SNR, Phae.snr$sound.files, FUN = rank) <= 5, ]

# Double check the number of selection per sound files 
table(Phae.hisnr$sound.files)

write.csv(Phae.hisnr, "Phae_lon_autodetec_selecs.csv", row.names = FALSE)

# Note that the dominant frequency measurements are almost always more accurate
trackfreqs(Phae.hisnr, flim = c(1, 11), bp = c(1, 12), it = "tiff")

# We can change the lower end of bandpass to make the frequency measurements more precise
trackfreqs(Phae.hisnr, flim = c(1, 11), bp = c(2, 12), col = c("purple", "orange"),
           pch = c(17, 3), res = 300, it = "tiff")

# If the frequency measurements look acceptable with this bandpass setting,
# that's the setting we should use when running specan() 

# Use the bandpass filter to your advantage, to filter out low or high background
# noise before performing measurements
# The amplitude threshold will change the amplitude at which noises are
# detected for measurements 
params <- specan(Phae.hisnr, bp = c(1, 11), threshold = 15)

View(params)

str(params)

# As always, it's a good idea to write .csv files to your working directory

