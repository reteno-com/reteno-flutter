import com.reteno.core.domain.model.user.Address
import com.reteno.core.domain.model.user.User
import com.reteno.core.domain.model.user.UserAttributes
import com.reteno.core.domain.model.user.UserCustomField

class UserUtils {
    companion object {
        fun parseUser(map: HashMap<*, *>): User? {
            val userMap = map["user_info"] as HashMap<*, *>? ?: return null

            val subscriptionKeys = userMap["subscriptionKeys"] as? List<String>?
            val groupNamesInclude = userMap["groupNamesInclude"] as? List<String>?
            val groupNamesExclude = userMap["groupNamesExclude"] as? List<String>?
            val userAttributesMap = userMap["userAttributes"] as HashMap<*, *>?

            if (userAttributesMap == null && subscriptionKeys == null && groupNamesExclude == null && groupNamesInclude == null) {
                return null
            }
            val phone = getStringOrNull(userAttributesMap?.get("phone") as String?)
            val email = getStringOrNull(userAttributesMap?.get("email") as String?)
            val firstName = getStringOrNull(userAttributesMap?.get("firstName") as String?)
            val lastName = getStringOrNull(userAttributesMap?.get("lastName") as String?)
            val languageCode = getStringOrNull(userAttributesMap?.get("languageCode") as String?)
            val timeZone = getStringOrNull(userAttributesMap?.get("timeZone") as String?)

            val addressMap = userAttributesMap?.get("address") as HashMap<*, *>?
            var userAddress: Address? = null
            if (addressMap != null) {
                val region = getStringOrNull(addressMap["region"] as String?)
                val town = getStringOrNull(addressMap["town"] as String?)
                val address = getStringOrNull(addressMap["address"] as String?)
                val postcode = getStringOrNull(addressMap["postcode"] as String?)
                userAddress = Address(
                    region, town, address, postcode,
                )
            }

            val customFieldsListMap = userAttributesMap?.get("fields") as List<HashMap<*, *>>?

            val userFields = customFieldsListMap?.map {
                UserCustomField(
                    it["key"] as String,
                    it["value"] as String?
                )
            }

            return User(
                UserAttributes(
                    phone, email, firstName, lastName, languageCode, timeZone,
                    userAddress,
                    userFields,
                ),
                subscriptionKeys, groupNamesInclude, groupNamesExclude
            )
        }

        private fun getStringOrNull(input: String?): String? {
            return if (input.isNullOrEmpty()) null else input
        }
    }
}