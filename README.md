# Wanted FB Api Calls

You don't have to know the e-mail or the phone number of your victim. You just have to know the account ID and you have to choose your dictionary file. 

Despite the fact you don't have to looking for private informations with my script, there are disavantages :
- This tool is more a proof of concept than a hacking tool.
- The multithreading isn't possible ( parallelised jobs too ).
- You can only test approx 10 ~ 15 passwords per one account sequentially. Otherwise, the API will block the login feature and probably your IP address.

<pre>usage : ./bruteForceFbGraphApi.sh -u ${UID} -d ${txt_dict} </pre>
