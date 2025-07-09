package com.reteno.reteno_plugin

import com.reteno.core.domain.model.event.Event
import com.reteno.core.domain.model.event.Parameter
import java.time.ZonedDateTime

object RetenoEvent {
    @Throws(Exception::class)
    fun buildEventFromCustomEvent(customEvent: NativeCustomEvent): Event {

        val stringDate = customEvent.dateOccurred
        val inputParameters = customEvent.parameters

        var parameters: List<Parameter>? = null

        val date: ZonedDateTime = ZonedDateTime.parse(stringDate)

        parameters = inputParameters.mapNotNull { entry ->
            entry?.let {
                it.value?.let { it1 ->
                    Parameter(
                        it.name,
                        it1
                    )
                }
            }
        }

        return Event.Custom(customEvent.eventTypeKey, date, parameters)
    }
}
