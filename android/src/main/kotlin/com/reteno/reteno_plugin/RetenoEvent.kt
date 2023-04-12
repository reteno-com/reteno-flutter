package com.reteno.reteno_plugin

import com.reteno.core.domain.model.event.Event
import com.reteno.core.domain.model.event.Parameter
import java.time.ZonedDateTime

object RetenoEvent {
    private fun buildEventParameters(inputParameters: List<Map<String, Any>>): List<Parameter>? {
        val countView = inputParameters.size
        if (countView == 0) return null

        val list: MutableList<Parameter> = ArrayList()
        for (i in 0 until countView) {
            val field = inputParameters[i]

            var name: String? = null
            var value: String? = null

            if (field["name"] is String) {
                name = field["name"] as String
            }
            if (field["value"] is String) {
                value = field["value"] as String
            }

            if (name != null) {
                list.add(Parameter(name, value))
            }
        }

        return list
    }

    @Throws(Exception::class)
    fun buildEventFromPayload(payload: Map<String, Any>): Event {
        val eventName = payload["event_type_key"] as? String
        val stringDate = payload["date_occurred"] as? String
        val inputParameters = (payload["parameters"] as? List<*>)?.filterIsInstance<Map<String, Any>>()

        var parameters: List<Parameter>? = null

        if (eventName == null) {
            throw Exception("logEvent: missing 'eventName' parameter!")
        }

        val date: ZonedDateTime = if (stringDate != null) {
            ZonedDateTime.parse(stringDate)
        } else {
            ZonedDateTime.now()
        }

        if (inputParameters != null) {
            parameters = buildEventParameters(inputParameters)
        }

        return Event.Custom(eventName, date, parameters)
    }
}
