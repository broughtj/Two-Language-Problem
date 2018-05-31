import requests
from datetime import datetime


def getJson(url):
	r = requests.get(url)
	return r.json()

def printSummary(inst):
	r = requests.get("https://www.deribit.com/api/v1/public/getsummary?instrument="+inst)
	json = r.json()
	json = json["estDelPrice"]
	print(json)
	#print("name:",json["instrumentName"], "bid:", json["bidPrice"], "ask:",json["askPrice"], "mid:",json["midPrice"])

def volumeAndBTC(time):
	volumeURL = "https://www.deribit.com/api/v1/public/stats"
	btcURL = "https://www.deribit.com/api/v1/public/index"
	volJson = getJson(volumeURL)
	btcJson = getJson(btcURL)
	with open("derivativeVolume.txt", "a+") as output:
		putsVol = volJson["result"]["btc_usd"]["putsVolume"]
		callsVol = volJson["result"]["btc_usd"]["callsVolume"]
		futuresVol = volJson["result"]["btc_usd"]["futuresVolume"]
		output.write(str(time)+","+str(btcJson["result"]["btc"])+","+str(futuresVol)+","+str(putsVol)+","+str(callsVol)+"\n")
	output.close()
	return

def writeFuture(obj,time):
	with open("derivativeFutures.txt", "a+") as output:
		json = getJson("https://www.deribit.com/api/v1/public/getsummary?instrument="+obj["instrumentName"])
		json = json["result"]
		output.write(time+",future,"+obj["instrumentName"]+","+obj["settlement"]+","+obj["created"]+","+obj["expiration"]+","+str(json["openInterest"])+","+str(json["high"])+","+str(json["low"])+","+str(json["volume"])+","+str(json["volumeBtc"])+","+str(json["bidPrice"])+","+str(json["askPrice"])+","+str(json["midPrice"])+"\n")
	output.close()
	return

def writeWeek(obj,time):
	with open("derivativeWeek.txt", "a+") as output:
		json = getJson("https://www.deribit.com/api/v1/public/getsummary?instrument="+obj["instrumentName"])
		json = json["result"]
		output.write(time+","+obj["kind"]+","+obj["instrumentName"]+","+obj["settlement"]+","+obj["created"]+","+obj["expiration"]+","+str(json["openInterest"])+","+str(json["high"])+","+str(json["low"])+","+str(json["volume"])+","+str(json["volumeBtc"])+","+str(json["bidPrice"])+","+str(json["askPrice"])+","+str(json["midPrice"])+"\n")
	output.close()
	return

def writeMonth(obj,time):
	with open("derivativeMonth.txt", "a+") as output:
		json = getJson("https://www.deribit.com/api/v1/public/getsummary?instrument="+obj["instrumentName"])
		json = json["result"]
		output.write(time+","+obj["kind"]+","+obj["instrumentName"]+","+obj["settlement"]+","+obj["created"]+","+obj["expiration"]+","+str(json["openInterest"])+","+str(json["high"])+","+str(json["low"])+","+str(json["volume"])+","+str(json["volumeBtc"])+","+str(json["bidPrice"])+","+str(json["askPrice"])+","+str(json["midPrice"])+"\n")
	output.close()
	return


def fillOptions(time):
	instrumentURL = "https://www.deribit.com/api/v1/public/getinstruments"
	json = getJson(instrumentURL)
	for obj in json["result"]:
		if obj["kind"] == "future":
			writeFuture(obj,time)
		elif obj["settlement"] == "week":
			writeWeek(obj,time)
		elif obj["settlement"] == "month":
			writeMonth(obj,time)
		else:
			print("what the hell?")
		print("finished: "+str(obj["instrumentName"]))



time = datetime.now().strftime('%Y-%m-%d %H:%M')
volumeAndBTC(time)
fillOptions(time)