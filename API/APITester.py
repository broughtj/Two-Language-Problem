import requests

#These are all of the possible requests for a public API
#this url tests the connection
url_test = "https://www.deribit.com/api/v1/public/test"

#gets kind(option), currencies, tickSize, strike, type, startDate, endDate 
url_instrunments = "https://www.deribit.com/api/v1/public/getinstruments"

#gets 'result': {'btc': 7890.24, 'edp': 7890.24} price and edp?
url_index = "https://www.deribit.com/api/v1/public/index"

#gets tells you it is using BTC? kinda worthless
url_currencies = "https://www.deribit.com/api/v1/public/getcurrencies"

#gets bids and asks for a specific option. Option instrunment. Also high and low of 24 hr.
url_orderBook = "https://www.deribit.com/api/v1/public/getorderbook?instrument=BTC-29JUN18-30000-C"

#gets last trades info for a specific option. instrunment is parameter, optional parameters: since(date) and count(of trades)
url_lastTrades = "https://www.deribit.com/api/v1/public/getlasttrades"

#gets a summary of item: openInterest, high, low, volume, last, bidPrice, askPrice, midPrice, createdDate
url_summary = "https://www.deribit.com/api/v1/public/getsummary"

#gets btc->usd stats, ie. futuresVolume, putsVolume, callsVolume
url_stats = "https://www.deribit.com/api/v1/public/stats"



def getJson(url):
	r = requests.get(url)
	return r.json()

def printSummary(inst):
	r = requests.get("https://www.deribit.com/api/v1/public/getsummary?instrument="+inst)
	json = r.json()
	json = json["result"]
	print("name:",json["instrumentName"], "bid:", json["bidPrice"], "ask:",json["askPrice"], "mid:",json["midPrice"])

json = getJson(url_instrunments)

#for obj in json["result"]:
#	printSummary(obj["instrumentName"])

count = 0
for obj in json["result"]:
	-printSummary(obj["instrumentName"])
#	count+=1
#print(count)
#printSummary("BTC-29JUN18-30000-C")
