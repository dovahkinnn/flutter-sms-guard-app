package com.dovahkin.sms_guard



import android.annotation.SuppressLint
import android.app.*
import android.app.role.RoleManager
import android.content.*
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.task.core.BaseOptions
import org.tensorflow.lite.task.text.nlclassifier.NLClassifier


class MainActivity: FlutterActivity() {



    @SuppressLint("SuspiciousIndentation")
    @RequiresApi(Build.VERSION_CODES.Q)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.dovahkin.sms_guard")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "bert") {
             
                showDefaultSmsDialog(this)

                result.success("Success")
            }
            if (call.method == "check") {
                val data = call.arguments as? Map<String, Any>
                val address = data?.get("address") as? String
                val message = data?.get("body") as? String
                saveinbox(this, address, message)
                result.success("mesaj kutusuna kaydeddildi")

            }
            if (call.method == "nlClassifier") {
                val data = call.arguments as?  String

                    val options = NLClassifier.NLClassifierOptions
                        .builder()
                        .setBaseOptions(BaseOptions.builder().setNumThreads(4).build())
                        .build()
                    val bertClassifier = NLClassifier.createFromFileAndOptions(
                        context,
                        "model (2).tflite",
                        options
                    )
                    val classifier = bertClassifier.classify(data)

                    bertClassifier.close()
                    println(classifier)
                    result.success(classifier)


            }
   

        }
        // val eventchannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.myapp/sms")
        // eventchannel.setStreamHandler(object : EventChannel.StreamHandler {
        //     override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        //         val filter = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
        //         registerReceiver(SMSReciver(events), filter)

        //     }

        //     override fun onCancel(arguments: Any?) {
        //         unregisterReceiver(SMSReciver(null))
        //     }
        // })
    }
    fun saveinbox(context: Context, address: String? = null, message: String? = null) {

        val smsValues = ContentValues()
        smsValues.put(Telephony.Sms.ADDRESS, address)

        smsValues.put(Telephony.Sms.BODY,   message)
        smsValues.put(Telephony.Sms.DATE, System.currentTimeMillis())
        smsValues.put(Telephony.Sms.READ, 0)
        smsValues.put(Telephony.Sms.SEEN,0)
        smsValues.put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)

        context.contentResolver.insert(Uri.parse("content://sms/inbox"), smsValues)
    }
    fun showDefaultSmsDialog(context: Activity) {
        if (intent.getBooleanExtra(Telephony.Sms.Intents.EXTRA_IS_DEFAULT_SMS_APP, false)){
            println("Default SMS app")
        }
        else{
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = context.getSystemService(RoleManager::class.java) as RoleManager
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                context.startActivityForResult(intent, 42389)
            } else {
                val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, context.packageName)
                context.startActivity(intent)
            }

        }


    }
    // fun permissionCheck() {
    //     if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    //         if (checkSelfPermission(android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
    //             requestPermissions(arrayOf(android.Manifest.permission.READ_SMS), 1)
    //         }
    //         if (checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
    //             requestPermissions(arrayOf(android.Manifest.permission.READ_CONTACTS), 1)
    //         }
    //     }
    // }



    }






