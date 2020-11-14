/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/10/29 - for the TOUS-ANTI-COVID project
 */

package com.lunabeestudio.stopcovid.fragment

import android.content.SharedPreferences
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.navigation.fragment.findNavController
import androidx.preference.PreferenceManager
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.lunabeestudio.stopcovid.coreui.manager.StringsManager
import com.lunabeestudio.stopcovid.databinding.FragmentPostalCodeBottomSheetBinding
import com.lunabeestudio.stopcovid.extension.chosenPostalCode
import com.lunabeestudio.stopcovid.extension.showPostalCodeDialog

class PostalCodeBottomSheetFragment : BottomSheetDialogFragment() {

    private val sharedPrefs: SharedPreferences by lazy {
        PreferenceManager.getDefaultSharedPreferences(requireContext())
    }

    private val strings: HashMap<String, String> = StringsManager.strings

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val binding = FragmentPostalCodeBottomSheetBinding.inflate(inflater, container, false)

        binding.changeButton.apply {
            text = strings["home.infoSection.updatePostalCode.alert.newPostalCode"]
            setOnClickListener {
                showPostalCodeDialog()
            }
        }

        binding.deleteButton.apply {
            text = strings["home.infoSection.updatePostalCode.alert.deletePostalCode"]
            setOnClickListener {
                sharedPrefs.chosenPostalCode = null
                dismissDialog(true)
            }
        }

        binding.cancelButton.apply {
            text = strings["common.cancel"]
            setOnClickListener {
                dismissDialog(false)
            }
        }
        return binding.root
    }

    private fun showPostalCodeDialog() {
        MaterialAlertDialogBuilder(requireContext()).showPostalCodeDialog(
            layoutInflater,
            strings
        ) { postalCode ->
            if (sharedPrefs.chosenPostalCode != postalCode) {
                sharedPrefs.chosenPostalCode = postalCode
                dismissDialog(true)
            } else {
                dismissDialog(false)
            }
        }
    }

    private fun dismissDialog(shouldRefresh: Boolean) {
        findNavController().previousBackStackEntry?.savedStateHandle?.set(SHOULD_BE_REFRESHED_KEY, shouldRefresh)
        this@PostalCodeBottomSheetFragment.dismiss()
    }

    companion object {
        const val SHOULD_BE_REFRESHED_KEY: String = "Should.Be.Refreshed"
    }
}