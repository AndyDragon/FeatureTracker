﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

namespace FeatureTracker
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class PageEditor : Windows.UI.Xaml.Controls.Page
    {
        public static readonly BlankViewModel blankViewModel = new BlankViewModel { Message = "Select a feature" };

        public PageEditor()
        {
            this.InitializeComponent();
            EditorFrame.Navigate(typeof(BlankPage), blankViewModel);
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

            if (DataContext is MainViewModel viewModel && e.Parameter is Page page)
            {
                ConnectPage(viewModel, page);
            }
        }

        private void ConnectPage(MainViewModel viewModel, Page page)
        {
            page.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "SelectedFeature")
                {
                    if (page.SelectedFeature != null && page.SelectedFeature.EditorPageType != null)
                    {
                        EditorFrame.Navigate(page.SelectedFeature.EditorPageType, page.SelectedFeature);
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