package com.hifi.music.di

import com.hifi.music.viewModel.AlbumViewModel
import com.hifi.music.utils.VersionManager
import com.hifi.music.viewModel.AnalyticsViewModel
import com.hifi.music.viewModel.ListenTogetherSettingsViewModel
import com.hifi.music.viewModel.ListenTogetherViewModel
import com.hifi.music.viewModel.ArtistViewModel
import com.hifi.music.viewModel.BrowseViewModel
import com.hifi.music.viewModel.HomeViewModel
import com.hifi.music.viewModel.ImportViewModel
import com.hifi.music.viewModel.LibraryDynamicPlaylistViewModel
import com.hifi.music.viewModel.LibraryViewModel
import com.hifi.music.viewModel.LocalPlaylistViewModel
import com.hifi.music.viewModel.LogInViewModel
import com.hifi.music.viewModel.LoginSyncHostViewModel
import com.hifi.music.viewModel.LoginSyncSenderViewModel
import com.hifi.music.viewModel.MoodViewModel
import com.hifi.music.viewModel.MoreAlbumsViewModel
import com.hifi.music.viewModel.NotificationViewModel
import com.hifi.music.viewModel.NowPlayingBottomSheetViewModel
import com.hifi.music.viewModel.PlaylistViewModel
import com.hifi.music.viewModel.PodcastViewModel
import com.hifi.music.viewModel.RecentlySongsViewModel
import com.hifi.music.viewModel.SearchViewModel
import com.hifi.music.viewModel.AutoEqViewModel
import com.hifi.music.viewModel.SettingsViewModel
import com.hifi.music.viewModel.SharedViewModel
import com.hifi.music.viewModel.SongSelectionViewModel
import com.hifi.music.viewModel.TasteViewModel
import com.hifi.music.viewModel.WrappedViewModel
import org.koin.core.module.dsl.viewModel
import org.koin.dsl.module

val viewModelModule =
    module {
        single {
            SharedViewModel(
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
            )
        }
        single {
            SearchViewModel(
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            SongSelectionViewModel(
                get(),
                get(),
            )
        }
        // Only one of these resolves on a given platform: Desktop binds the host repository, Android the
        // sender. Koin resolves dependencies when a ViewModel is created, not when it is declared.
        viewModel { LoginSyncHostViewModel(get()) }
        viewModel { LoginSyncSenderViewModel(get()) }
        viewModel {
            NowPlayingBottomSheetViewModel(
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            LibraryViewModel(
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            LibraryDynamicPlaylistViewModel(
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            ImportViewModel(
                get(),
            )
        }
        viewModel {
            AlbumViewModel(
                get(),
                get(),
            )
        }
        viewModel {
            HomeViewModel(
                get(),
                get(),
            )
        }
        viewModel {
            AutoEqViewModel(
                get(),
                get(),
            )
        }
        viewModel {
            SettingsViewModel(
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            ArtistViewModel(
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            PlaylistViewModel(
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            LogInViewModel(
                get(),
            )
        }
        viewModel {
            PodcastViewModel(
                get(),
            )
        }
        viewModel {
            MoreAlbumsViewModel(
                get(),
            )
        }
        viewModel {
            BrowseViewModel(
                get(),
            )
        }
        viewModel {
            RecentlySongsViewModel(
                get(),
            )
        }
        viewModel {
            LocalPlaylistViewModel(
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            NotificationViewModel(
                get(),
            )
        }
        viewModel {
            MoodViewModel(
                get(),
                get(),
            )
        }
        viewModel {
            AnalyticsViewModel(
                get(),
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            WrappedViewModel(
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            TasteViewModel(
                get(),
                get(),
                get(),
                get(),
                get(),
                get(),
            )
        }
        viewModel {
            ListenTogetherSettingsViewModel(get())
        }
        viewModel {
            ListenTogetherViewModel(
                repository = get(),
                dataStore = get(),
                bridge = get(),
            )
        }

    }