library('warbleR')
#for (i in 1:10){
#checkwavbit<-3
#tryCatch(checkwavs(),error=function(e){next})
#print(checkwavbit)
#}

for (i in 1:10){
	possibleError <- tryCatch(checkwavs(),error = function(e){print(e)})
	if(inherits(possibleError,"error")) {
		next
	}
	print("all good")
}
