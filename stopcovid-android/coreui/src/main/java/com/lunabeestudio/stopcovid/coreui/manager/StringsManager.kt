/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/13/05 - for the TOUS-ANTI-COVID project
 */

package com.lunabeestudio.stopcovid.coreui.manager

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.google.gson.reflect.TypeToken
import com.lunabeestudio.stopcovid.coreui.R
import com.lunabeestudio.stopcovid.coreui.UiConstants
import com.lunabeestudio.stopcovid.coreui.extension.fixFormatter
import java.lang.reflect.Type
import java.util.Locale

object StringsManager : ServerManager() {

    var strings: HashMap<String, String> = hashMapOf()
        private set(value) {
            if (field != value) {
                _liveStrings.postValue(value)
            }
            field = value
        }

    private val _liveStrings: MutableLiveData<HashMap<String, String>> = MutableLiveData()
    val liveStrings: LiveData<HashMap<String, String>>
        get() = _liveStrings

    private var prevLanguage: String? = null

    suspend fun initialize(context: Context) {
        prevLanguage = Locale.getDefault().language
        loadLocal<HashMap<String, String>>(context, false)?.let {
            strings = it
        }
    }

    suspend fun onAppForeground(context: Context) {
        val forceRefresh = prevLanguage != Locale.getDefault().language
        val hasFetch = fetchLast(context, forceRefresh)
        if (hasFetch || forceRefresh) {
            loadLocal<HashMap<String, String>>(context, forceRefresh)?.let {
                prevLanguage = Locale.getDefault().language
                strings = it
            }
        }
    }

    override fun folderName(): String = "Strings"
    override fun prefix(context: Context): String = context.getString(R.string.string_prefix)
    override fun type(): Type = object : TypeToken<HashMap<String, String>>() {}.type
    override fun lastRefreshSharedPrefsKey(): String = UiConstants.SharePrefs.LAST_STRINGS_REFRESH
    override fun transform(input: String): String = input.fixFormatter()
}