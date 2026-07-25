package com.android.lancarkan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class BackgroundLocationService : Service() {

    private val CHANNEL_ID = "NavLocationChannel"
    private val NOTIFICATION_ID = 1

    private lateinit var locationManager: LocationManager
    private var mockJob: Job? = null
    
    // Default location values
    private var currentLat: Double = 0.0
    private var currentLng: Double = 0.0
    private var currentAlt: Double = 0.0
    private var currentBearing: Float = 0.0f
    private var currentSpeed: Float = 0.0f
    private var currentAccuracy: Float = 1.0f

    private val updateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_UPDATE_LOCATION) {
                currentLat = intent.getDoubleExtra("lat", currentLat)
                currentLng = intent.getDoubleExtra("lng", currentLng)
                currentAlt = intent.getDoubleExtra("alt", currentAlt)
                currentBearing = intent.getFloatExtra("bearing", currentBearing)
                currentSpeed = intent.getFloatExtra("speed", currentSpeed)
                currentAccuracy = intent.getFloatExtra("accuracy", currentAccuracy)
                updateNotification()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
        
        val filter = IntentFilter(ACTION_UPDATE_LOCATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(updateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(updateReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopMocking()
            stopForeground(STOP_FOREGROUND_REMOVE)
            sendBroadcast(Intent(ACTION_NAV_STOPPED).setPackage(packageName))
            stopSelf()
            return START_NOT_STICKY
        }

        // Extract initial values
        intent?.let {
            currentLat = it.getDoubleExtra("lat", 0.0)
            currentLng = it.getDoubleExtra("lng", 0.0)
            currentAlt = it.getDoubleExtra("alt", 0.0)
            currentBearing = it.getFloatExtra("bearing", 0.0f)
            currentSpeed = it.getFloatExtra("speed", 0.0f)
            currentAccuracy = it.getFloatExtra("accuracy", 1.0f)
        }

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        startMocking()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        unregisterReceiver(updateReceiver)
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Navigation Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val speedKmh = currentSpeed * 3.6
        val title = "Navigasi Berjalan"
        val content = "Lat: %.5f, Lng: %.5f, Kec: %.1f km/h".format(currentLat, currentLng, speedKmh)

        val stopIntent = Intent(this, BackgroundLocationService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_stat_location)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Hentikan",
                stopPendingIntent,
            )
            .build()
    }

    private fun updateNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, createNotification())
    }

    private fun startMocking() {
        setupTestProvider(LocationManager.GPS_PROVIDER)
        setupTestProvider(LocationManager.NETWORK_PROVIDER)
        setupTestProvider("fused")

        mockJob?.cancel()
        mockJob = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                publishLocation(LocationManager.GPS_PROVIDER)
                publishLocation(LocationManager.NETWORK_PROVIDER)
                publishLocation("fused")
                
                delay(1000)
            }
        }
    }

    private fun setupTestProvider(provider: String) {
        try {
            locationManager.addTestProvider(
                provider,
                false,
                false,
                false,
                false,
                true,
                true,
                true,
                1,
                1
            )
            locationManager.setTestProviderEnabled(provider, true)
        } catch (e: SecurityException) {
            e.printStackTrace()
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                android.widget.Toast.makeText(this, "Izin Mock Ditolak! Pilih aplikasi ini di Dev Options.", android.widget.Toast.LENGTH_LONG).show()
            }
        } catch (e: IllegalArgumentException) {
            try {
                locationManager.setTestProviderEnabled(provider, true)
            } catch (ex: Exception) {
                ex.printStackTrace()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun publishLocation(provider: String) {
        val mockLocation = Location(provider).apply {
            latitude = currentLat
            longitude = currentLng
            altitude = currentAlt
            bearing = currentBearing
            speed = currentSpeed
            accuracy = currentAccuracy
            time = System.currentTimeMillis()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                bearingAccuracyDegrees = 0.1f
                verticalAccuracyMeters = 0.1f
                speedAccuracyMetersPerSecond = 0.1f
            }
            
            // Fix for Android 12+ (API 31+) isMock flag
            try {
                val method = Location::class.java.getMethod("setIsFromMockProvider", Boolean::class.javaPrimitiveType)
                method.invoke(this, true)
            } catch (e: Exception) {
                // Ignore if method not found (older Androids)
            }
        }

        try {
            locationManager.setTestProviderLocation(provider, mockLocation)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopMocking() {
        mockJob?.cancel()
        try {
            locationManager.removeTestProvider(LocationManager.GPS_PROVIDER)
            locationManager.removeTestProvider(LocationManager.NETWORK_PROVIDER)
            locationManager.removeTestProvider("fused")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    companion object {
        const val ACTION_UPDATE_LOCATION = "com.android.lancarkan.UPDATE_LOCATION"
        const val ACTION_STOP = "com.android.lancarkan.STOP"
        const val ACTION_NAV_STOPPED = "com.android.lancarkan.NAV_STOPPED"
    }
}
