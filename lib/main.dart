import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cashfree_pg/cashfree_pg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
/*
hey everyone , in this video we are going to see how to verify cashfree payment signature
i will start from where our cashfree integration video ended.
so to verify signature  , you will get the codes in cashfree documentation
as you see there are many languages available to verify 
and remember this verify should happen at backend
in this video we are going to use php code
i have just copied there code 
in my localhost i am going to call these php code
so let's write code to call our php code for verification of signature

that's all you have to do to verify signature
thanks for watching


*/

  final TextEditingController _amountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          child: Text(
            "CashFree Payment signature verification",
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //  amount input field
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 20,
            ),
            child: TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
                hintText: "Enter amount",
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          //  pay button
          ElevatedButton(
            child: const Text("Pay"),
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
              final amount = _amountController.text.trim();
              if (amount.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Enter amount"),
                  ),
                );
                return;
              }

              num orderId = Random().nextInt(1000);

              num payableAmount = num.parse(amount);
              getAccessToken(payableAmount, orderId).then((tokenData) {
                Map<String, String> _params = {
                  'stage': 'TEST',
                  'orderAmount': amount,
                  'orderId': '$orderId',
                  'orderCurrency': 'INR',
                  'customerName': 'ARY',
                  'customerPhone': '9012345678',
                  'customerEmail': 'ary@gmail.com',
                  'tokenData': tokenData,
                  'appId': '160073684d17e325cb18d7b158370061',
                };
                CashfreePGSDK.doPayment(_params).then((value) {
                  if (value != null) {
                    //  on success of our payment we are going to verify
                    if (value['txStatus'] == 'SUCCESS') {
                      verifySignature(value);// pass response of doPayment to verifySignature funtion
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("Payment Success"),
                      //   ),
                      // );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Payment Failed"),
                        ),
                      );
                    }
                  }
                });
              });
            },
          ),
        ],
      ),
    );
  }

  verifySignature(Map<dynamic, dynamic> value) async {
    Map<String, dynamic> body = {
      "txStatus": value['txStatus'],
      "orderAmount": value['orderAmount'],
      "paymentMode": value['paymentMode'],
      "orderId": value['orderId'],
      "txTime": value['txTime'],
      "signature": value['signature'],
      "txMsg": value['txMsg'],
      "type": value['type'],
      "referenceId": value[
          'referenceId'], // these values you will get in response of payment success
    };

//  it's a POST url encoded request 
//  below codes are for that
//  url encoded request
    var parts = [];
    body.forEach((key, value) {
      parts.add('${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(value)}');
    });
    var formData = parts.join('&');
    var res = await http.post(
      Uri.https(
        "192.168.72.76",// my ip address , localhost
        "signature_verify.php",
      ),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded", // urlencoded 
      },
      body: formData,
    );

    if (res.statusCode == 200) {
      //  on success of api call we are checking if signature matched or not 
      //  if response is true then it matched
      //  else not match
      if (res.body == 'true') {
        //  on match we are showing this snackbar , you have to do your action here
        //  like after purchase functionalities 
        //  let's run this code
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Success"),
          ),
        );
      }
    }
  }

  Future<String> getAccessToken(num amount, num orderId) async {
    var res = await http.post(
      Uri.https("test.cashfree.com", "api/v2/cftoken/order"),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-client-id': "160073684d17e325cb18d7b158370061",
        'x-client-secret': "414934a7a49ca8d107031a2820656cac28e7b024",
      },
      body: jsonEncode(
        {
          "orderId": '$orderId',
          "orderAmount": amount,
          "orderCurrency": "INR",
        },
      ),
    );
    if (res.statusCode == 200) {
      var jsonResponse = jsonDecode(res.body);
      if (jsonResponse['status'] == 'OK') {
        return jsonResponse['cftoken'];
      }
    }
    return '';
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
