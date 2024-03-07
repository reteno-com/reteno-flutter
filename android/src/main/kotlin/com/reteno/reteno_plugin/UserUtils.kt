import com.reteno.core.domain.model.user.*
import com.reteno.reteno_plugin.NativeAnonymousUserAttributes
import com.reteno.reteno_plugin.NativeRetenoUser

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
                    it["key"] as String, it["value"] as String?
                )
            }

            return User(
                UserAttributes(
                    phone, email, firstName, lastName, languageCode, timeZone,
                    userAddress,
                    userFields,
                ), subscriptionKeys, groupNamesInclude, groupNamesExclude
            )
        }

        fun fromRetenoUser(retenoUser: NativeRetenoUser?): User? {
            if (retenoUser == null) {
                return null
            }
            val subscriptionKeys = retenoUser.subscriptionKeys
            val groupNamesInclude = retenoUser.groupNamesInclude
            val groupNamesExclude = retenoUser.groupNamesExclude
            val userAttributes = retenoUser.userAttributes

            if (userAttributes == null
                && subscriptionKeys == null
                && groupNamesExclude == null
                && groupNamesInclude == null) {
                return null
            }

            var userAddress: Address? = null
            if (userAttributes?.address != null) {
                var address = userAttributes.address
                userAddress = Address(
                    address.region, address.town, address.address, address.postcode,
                )
            }

            val customFieldsList = userAttributes?.fields

            val userFields = customFieldsList?.mapNotNull { entry ->
                entry?.let {
                    UserCustomField(
                        it.key,
                        it.value
                    )
                }
            }

            return User(
                UserAttributes(
                    userAttributes?.phone,
                    userAttributes?.email,
                    userAttributes?.firstName,
                    userAttributes?.lastName,
                    userAttributes?.languageCode,
                    userAttributes?.timeZone,
                    userAddress,
                    userFields
                ),
                subscriptionKeys?.filterNotNull()?.mapNotNull { it },
                groupNamesInclude?.filterNotNull()?.mapNotNull { it },
                groupNamesExclude?.filterNotNull()?.mapNotNull { it },
            )
        }

        private fun getStringOrNull(input: String?): String? {
            return if (input.isNullOrEmpty()) null else input
        }

        fun parseAnonymousAttributes(anonymousUserAttributes: NativeAnonymousUserAttributes): UserAttributesAnonymous {

            val address = anonymousUserAttributes.address
            var userAddress: Address? = null
            if (address != null) {
                userAddress = Address(
                    address.region,
                    address.town,
                    address.address,
                    address.postcode,
                )
            }

            val customFieldsList = anonymousUserAttributes?.fields

            val userFields = customFieldsList?.mapNotNull { entry ->
                entry?.let {
                    UserCustomField(
                        it.key,
                        it.value
                    )
                }
            }

            return UserAttributesAnonymous(
                anonymousUserAttributes.firstName,
                anonymousUserAttributes.lastName,
                anonymousUserAttributes.languageCode,
                anonymousUserAttributes.timeZone,
                userAddress,
                userFields
            )
        }
    }
}