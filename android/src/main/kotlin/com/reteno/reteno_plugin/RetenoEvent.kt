package com.reteno.reteno_plugin

import com.reteno.core.domain.model.event.Event
import com.reteno.core.domain.model.event.Parameter
import java.time.ZonedDateTime

object RetenoEvent {
    @Throws(Exception::class)
    fun buildEventFromCustomEvent(customEvent: NativeCustomEvent): Event {
        if (customEvent.eventTypeKey == null) {
            throw Exception("logEvent: missing 'eventName' parameter!")
        }

        val stringDate = customEvent.dateOccurred
        val inputParameters = customEvent.parameters

        var parameters: List<Parameter>? = null

        val date: ZonedDateTime = if (stringDate != null) {
            ZonedDateTime.parse(stringDate)
        } else {
            ZonedDateTime.now()
        }

        if (inputParameters != null) {
            parameters = inputParameters?.mapNotNull { entry ->
                entry?.let {
                    Parameter(
                        it.name,
                        it.value
                    )
                }
            }
        }

        return Event.Custom(customEvent.eventTypeKey, date, parameters)
    }
}
