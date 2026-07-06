package com.example.find_my_friend

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    MapKitFactory.setApiKey("5de15677-efee-4a22-894e-4bb1836c9ed9")
  }
}
