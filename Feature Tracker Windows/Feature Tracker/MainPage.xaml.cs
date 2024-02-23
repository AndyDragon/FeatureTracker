﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Devices.Enumeration;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=402352&clcid=0x409

namespace FeatureTracker
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Windows.UI.Xaml.Controls.Page
    {
        public static readonly BlankViewModel blankViewModel = new BlankViewModel { Message = "Select a page" };

        public MainPage()
        {
            this.InitializeComponent();
            EditorFrame.Navigate(typeof(BlankPage), blankViewModel);
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

            if (DataContext is MainViewModel viewModel)
            {
                ConnectViewModel(viewModel);
            }
        }

        private void ConnectViewModel(MainViewModel viewModel)
        {
            viewModel.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "SelectedPage")
                {
                    if (viewModel.SelectedPage != null && viewModel.SelectedPage.EditorPageType != null)
                    {
                        EditorFrame.Navigate(viewModel.SelectedPage.EditorPageType, viewModel.SelectedPage);
                    }
                    else
                    {
                        EditorFrame.Navigate(typeof(BlankPage), blankViewModel);
                    }
                }
            };
        }
    }
}