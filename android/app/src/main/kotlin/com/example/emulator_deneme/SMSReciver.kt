package com.dovahkin.sms_guard


import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.tensorflow.lite.support.label.Category
import org.tensorflow.lite.task.core.BaseOptions
import org.tensorflow.lite.task.text.nlclassifier.BertNLClassifier


class SMSReciver( private val eventSink: EventChannel.EventSink? ) : BroadcastReceiver() {
    constructor() : this(null)


    override fun onReceive(context: Context, intent: Intent) {
        println("SMS received")


        val pdus: Array<*>
        val msgs: Array<SmsMessage?>
        var msgFrom: String?
        var msgText: String?

        val strBuilder = StringBuilder()
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            intent?.extras?.let {
                try {
                    pdus = it.get("pdus") as Array<*>
                    msgs = arrayOfNulls(pdus.size)
                    for (i in msgs.indices) {
                        msgs[i] = SmsMessage.createFromPdu(pdus[i] as ByteArray)
                        strBuilder.append(msgs[i]?.messageBody)
                    }

                    msgText = strBuilder.toString()
                    msgFrom = msgs[0]?.originatingAddress




                    if (!msgFrom.isNullOrBlank() && !msgText.isNullOrBlank()) {
//                        println("SmsReceiver: $msgText")
//                        println(msgs[0]?.pdu.toString())
//                        println(msgs[0]?.serviceCenterAddress.toString())
                        eventSink?.success(msgText)

                        var result = bertClassifier(msgText!!, context)
                        if (result != null) {
                            println(result)
                            if (result[0].score > result[1].score ) {
                          
                                println("Bet")
                                val db = DBHelper(context)
                                db.insertData(msgText.toString(), msgFrom.toString())


                            } else {
                                println("Not Bet")
                                var name=getcontactname(context,msgFrom.toString())
                                if (name!=null&&name!=""){

                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        notificationbuilding(context, name, msgText.toString())
                                    }
                                }else{
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        notificationbuilding(context, msgFrom.toString(), msgText.toString())
                                    }
                                }
                                saveinbox(context, msgFrom.toString(), msgText.toString())



                            }
                        }


                    }
                } catch (e: Exception) {
                }
            }
        }




    }
    fun saveinbox(context: Context, number: String, message: String) {

        val smsValues = ContentValues()
        smsValues.put(Telephony.Sms.ADDRESS, number)

        smsValues.put(Telephony.Sms.BODY, message)
        smsValues.put(Telephony.Sms.DATE, System.currentTimeMillis())

        context.contentResolver.insert(Uri.parse("content://sms/inbox"), smsValues)
    }
    @SuppressLint("Range")
    fun getcontactname(context: Context, number: String): String {

        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(
                number
            )
        )

        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)

        var contactName = ""
        val cursor: Cursor? = context.contentResolver.query(uri, projection, null, null, null)

        if (cursor != null) {
            if (cursor.moveToFirst()) {
                contactName = cursor.getString(0)
            }
            cursor.close()
        }


        return contactName!!
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun notificationbuilding(context: Context, number: String, message: String) {

        // val intent = Intent(context, MainActivity::class.java)
        // intent.flags =  Intent.FLAG_ACTIVITY_CLEAR_TASK
        // val pendingIntent = PendingIntent.getActivity(context, 0, intent, 0)
        val intent = context.packageManager.getLaunchIntentForPackage("com.dovahkin.sms_guard")
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, 0)
        val channel = NotificationChannel(
            "1",
            "mY CHANNEL",
            NotificationManager.IMPORTANCE_HIGH
        )
        channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        val builder = NotificationCompat.Builder(context, "1")
            .setSmallIcon(R.drawable.ic_baseline_sms_24)
            .setContentTitle(number.toString())
            .setContentText(message.toString())
            .setContentIntent(pendingIntent)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(message.toString()))
                .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(Notification.DEFAULT_ALL)

            .setVibrate(longArrayOf(1000, 1000, 1000, 1000, 1000))
            .setAutoCancel(true)
        builder.setDefaults(Notification.DEFAULT_VIBRATE);
        builder.setDefaults(Notification.DEFAULT_SOUND);

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager


       
        notificationManager.createNotificationChannel(channel)
        val notificationId = (System.currentTimeMillis() % 10000).toInt()

        notificationManager.notify(notificationId, builder.build())
      try {
          val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
          val r = RingtoneManager.getRingtone(context, uri)
          r.play()
      } catch (e: Exception) {
          e.printStackTrace()
      }

    }


    fun SmsMessage.toMap(): HashMap<String, Any?> {
        val smsMap = HashMap<String, Any?>()
        this.apply {
            smsMap["message_body"] = messageBody
            smsMap["timestamp"] = timestampMillis.toString()
            smsMap["originating_address"] = originatingAddress
            smsMap["status"] = status.toString()
            smsMap["service_center"] = serviceCenterAddress
        }
        return smsMap
    }




    fun bertClassifier(message: String, context: Context): MutableList<Category>? {
        val options = BertNLClassifier.BertNLClassifierOptions
            .builder()
            .setBaseOptions(BaseOptions.builder().setNumThreads(4).build())
            .build()
        val bertClassifier = BertNLClassifier.createFromFileAndOptions(
            context,
            "mobilebert_son.tflite",
            options
        )
        val classifier = bertClassifier.classify(message)

        bertClassifier.close()
        println(classifier)
        return classifier
    }








}