/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/04/05 - for the TOUS-ANTI-COVID project
 */

package com.lunabeestudio.stopcovid.fragment

import android.os.Bundle
import android.view.View
import androidx.core.view.updatePadding
import com.google.android.material.appbar.AppBarLayout
import com.lunabeestudio.stopcovid.activity.OnBoardingActivity
import com.lunabeestudio.stopcovid.coreui.extension.appCompatActivity
import com.lunabeestudio.stopcovid.coreui.extension.registerToAppBarLayoutForLiftOnScroll
import com.lunabeestudio.stopcovid.coreui.extension.safeEmojiSpanify
import com.lunabeestudio.stopcovid.coreui.fragment.FastAdapterFragment
import com.lunabeestudio.stopcovid.databinding.ActivityOnBoardingBinding

abstract class OnBoardingFragment : FastAdapterFragment() {

    abstract fun getTitleKey(): String
    abstract fun getButtonTitleKey(): String?
    abstract fun getOnButtonClick(): () -> Unit

    protected fun getActivityBinding(): ActivityOnBoardingBinding = (activity as OnBoardingActivity).binding
    private fun getActivityMergeBinding() = (activity as OnBoardingActivity).mergeBinding

    override fun getAppBarLayout(): AppBarLayout? = getActivityBinding().appBarLayout

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding?.recyclerView?.registerToAppBarLayoutForLiftOnScroll(getActivityBinding().appBarLayout)
        initBottomButton()
    }

    override fun refreshScreen() {
        super.refreshScreen()
        appCompatActivity?.supportActionBar?.title = strings[getTitleKey()]
        getActivityMergeBinding().bottomSheetButton.text = strings[getButtonTitleKey()].safeEmojiSpanify()
    }

    private fun initBottomButton() {
        getActivityMergeBinding().bottomSheetButton.setOnClickListener {
            getOnButtonClick().invoke()
        }
        getActivityMergeBinding().bottomSheetFrameLayout.post {
            binding?.recyclerView?.updatePadding(bottom = getActivityMergeBinding().bottomSheetFrameLayout.height)
        }
    }
}
