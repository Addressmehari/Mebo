package com.mebo.tracker

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class WidgetUpdateWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        // Update HaboWidget
        val haboWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HaboWidget::class.java)
        )
        for (appWidgetId in haboWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }

        // Update HaboWeekWidget
        val haboWeekWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HaboWeekWidget::class.java)
        )
        for (appWidgetId in haboWeekWidgetIds) {
            updateWeekWidget(context, appWidgetManager, appWidgetId)
        }

        return Result.success()
    }
}
