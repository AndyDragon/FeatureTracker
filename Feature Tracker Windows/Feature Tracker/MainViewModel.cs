using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;
using ControlzEx.Theming;
using MahApps.Metro.Controls.Dialogs;
using MahApps.Metro.IconPacks;
using Newtonsoft.Json;
using Notification.Wpf;

namespace FeatureTracker
{

    public class MainViewModel : NotifyPropertyChanged, IDataManager
    {
        private int operationCount = 0;

        public MainViewModel()
        {
            toggleSplitViewCommand = new Command(() => this.IsSplitViewPaneOpen = !this.IsSplitViewPaneOpen);
            addPageCommand = new Command(() =>
            {
                var page = new Page() { Name = "new page" };
                AddModel(page);
                Pages.Add(page);
                SelectedPage = page;
            });
            setPageSortCommand = new CommandWithParameter((parameter) =>
            {
                var compareMode = parameter != null
                    ? (PageComparer.CompareMode)parameter
                    : PageComparer.CompareMode.Name;
                switch (compareMode)
                {
                    case PageComparer.CompareMode.Name:
                        pageSort = PageComparer.NameComparer;
                        break;
                    case PageComparer.CompareMode.Count:
                        pageSort = PageComparer.CountComparer;
                        break;
                    case PageComparer.CompareMode.Features:
                        pageSort = PageComparer.FeaturesComparer;
                        break;
                }
                UserSettings.StoreInt("pageSort", (int)compareMode);
                RefreshPages();
            });
            refreshPagesCommand = new Command(() =>
            {
                RefreshPages();
            });
            populateDefaultsCommand = new Command(PopulateDefaultPages);
            generateReportCommand = new Command(GenerateReport);
            startBackupOperationCommand = new CommandWithParameter((parameter) =>
            {
                var operation = (parameter != null)
                    ? (BackupOperation)parameter
                    : BackupOperation.BackupToClipboard;
                switch (operation)
                {
                    case BackupOperation.BackupToClipboard:
                        BackupToClipboard();
                        break;
                    case BackupOperation.BackupToDocuments:
                        BackupToDocuments();
                        break;
                    case BackupOperation.RestoreFromClipboard:
                        RestoreFromClipboard();
                        break;
                    case BackupOperation.RestoreFromDocuments:
                        RestoreFromDocuments();
                        break;
                }
            });
            setThemeCommand = new CommandWithParameter((parameter) => 
            {
                if (parameter is Theme theme)
                {
                    Theme = theme;
                }
            });
            closePageCommand = new Command(() => SelectedPage = null);
            deletePageCommand = new Command(async () =>
            {
                if (!await ShowConfirmationMessage(
                    "Delete page / challenge",
                    "Are you sure you want to delete this page / challenge and all the features, this cannot be undone!"))
                {
                    return;
                }
                var page = SelectedPage;
                SelectedPage = null;
                if (page != null)
                {
                    Pages.Remove(page);
                    RemoveModel(page);
                }
                ShowToast("Deleted page", "Removed the page or challenge and all the features", NotificationType.Notification);
            });

            pageSort = (PageComparer.CompareMode)(UserSettings.GetInt("pageSort") ?? 0) switch
            {
                PageComparer.CompareMode.Count => PageComparer.CountComparer,
                PageComparer.CompareMode.Features => PageComparer.FeaturesComparer,
                _ => PageComparer.NameComparer,
            };
            AddModelCollection(Pages);
            StartOperation();
            LoadPages();
            Pages.SortBy(pageSort);
            StopOperation();
            foreach (var pageSortOption in pageSortOptions)
            {
                pageSortOption.IsSelected = pageSortOption.Comparer == pageSort;
            }
            OnPropertyChanged(nameof(PageSortOptions));
            UpdateSummary();
        }

        private static string GetDataLocationPath()
        {
            var user = WindowsIdentity.GetCurrent();
            var dataLocationPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AndyDragonSoftware",
                "FeatureTracker",
                user.Name);
            if (!Directory.Exists(dataLocationPath))
            {
                Directory.CreateDirectory(dataLocationPath);
            }
            return dataLocationPath;
        }

        private static string GetDataPath()
        {
            var dataLocationPath = GetDataLocationPath();
            return Path.Combine(dataLocationPath, "database.json");
        }

        public static string GetUserSettingsPath()
        {
            var dataLocationPath = GetDataLocationPath();
            return Path.Combine(dataLocationPath, "settings.json");
        }

        private void LoadPages()
        {
            try
            {
                var dataPath = GetDataPath();
                if (File.Exists(dataPath))
                {
                    var json = File.ReadAllText(dataPath);
                    if (!string.IsNullOrEmpty(json))
                    {
                        var loadedPages = JsonConvert.DeserializeObject<List<JsonPage>>(json);
                        if (loadedPages != null)
                        {
                            foreach (var loadedPage in loadedPages)
                            {
                                var page = new Page(loadedPage);
                                AddModel(page);
                                Pages.Add(page);
                            }
                            UpdateSummary();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
                ShowToast(
                    "Loading data failed",
                    "An error occurred loading the data from storage: " + ex.Message,
                    NotificationType.Error,
                    TimeSpan.FromSeconds(10));
            }
        }

        private void StorePages()
        {
            try
            {
                var dataPath = GetDataPath();
                var jsonPages = Pages.Select(page => page.ToJson());
                var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
                File.WriteAllText(dataPath, json);
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
                ShowToast(
                    "Saving data failed",
                    "An error occurred saving the data to storage: " + ex.Message,
                    NotificationType.Error,
                    TimeSpan.FromSeconds(10));
            }
        }

        private void RefreshPages()
        {
            SetBusy(true);
            StartOperation();
            var oldSelectedPage = SelectedPage;
            SelectedPage = null;
            Pages.SortBy(pageSort);
            StopOperation();
            SelectedPage = oldSelectedPage;
            foreach (var pageSortOption in pageSortOptions)
            {
                pageSortOption.IsSelected = pageSortOption.Comparer == pageSort;
            }
            OnPropertyChanged(nameof(PageSortOptions));
        }

        private static bool IsBusy { get; set; } = false;
        public static void SetBusy(bool busy)
        {
            if (busy != IsBusy)
            {
                IsBusy = busy;
                Mouse.OverrideCursor = IsBusy ? Cursors.Wait : null;
                if (IsBusy)
                {
                    _ = new DispatcherTimer(TimeSpan.FromSeconds(0.5), DispatcherPriority.ApplicationIdle, OnDispatcherTimerTick, Application.Current.Dispatcher);
                }
            }
        }

        private static void OnDispatcherTimerTick(object? sender, EventArgs e)
        {
            if (sender is DispatcherTimer dispatcherTimer)
            {
                SetBusy(false);
                dispatcherTimer.Stop();
            }
        }

        public void ShowToast(
            string title,
            string message,
            NotificationType type = NotificationType.Success,
            TimeSpan? duration = null)
        {
            notificationManager.Show(title, message, type: type, areaName: "WindowArea", expirationTime: duration ?? TimeSpan.FromSeconds(3));
        }

        public static async Task<bool> ShowConfirmationMessage(
            string title,
            string message)
        {
            // This demo runs on .Net 4.0, but we're using the Microsoft.Bcl.Async package so we have async/await support
            // The package is only used by the demo and not a dependency of the library!
            var settings = new MetroDialogSettings()
            {
                AffirmativeButtonText = "  Yes please  ",
                NegativeButtonText = "  No thanks  ",
                DialogButtonFontSize = 16D,
                DefaultButtonFocus = MessageDialogResult.Negative,
            };

            if (Application.Current?.MainWindow is MahApps.Metro.Controls.MetroWindow mainWindow)
            {
                return (await mainWindow.ShowMessageAsync(
                    title,
                    message,
                    MessageDialogStyle.AffirmativeAndNegative,
                    settings)) == MessageDialogResult.Affirmative;
            }
            else
            {
                return MessageBox.Show(
                    message,
                    title,
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question) == MessageBoxResult.Yes;
            }
        }

        private readonly NotificationManager notificationManager = new();

        public SortableModelCollection<Page> Pages { get; } = [];

        private PageComparer pageSort = PageComparer.NameComparer;

        private readonly SortOption<Page>[] pageSortOptions = [
            new SortOption<Page> { Comparer = PageComparer.NameComparer, Label = "Sort by Name", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Name },
            new SortOption<Page> { Comparer = PageComparer.CountComparer, Label = "Sort by Count", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Count },
            new SortOption<Page> { Comparer = PageComparer.FeaturesComparer, Label = "Sort by Features", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Features },
        ];
        public SortOption<Page>[] PageSortOptions => pageSortOptions;

        private readonly BackupOperationOption[] backupOperationOptions = [
            new BackupOperationOption { Label = "Backup to Clipboard", IconKind = PackIconMaterialKind.ClipboardArrowUpOutline, Operation = BackupOperation.BackupToClipboard },
            new BackupOperationOption { Label = "Backup to Documents", IconKind = PackIconMaterialKind.DatabaseArrowUpOutline, Operation = BackupOperation.BackupToDocuments },
            new BackupOperationOption { Label = "Restore from Clipboard", IconKind = PackIconMaterialKind.ClipboardArrowDownOutline, Operation = BackupOperation.RestoreFromClipboard },
            new BackupOperationOption { Label = "Restore from Documents", IconKind = PackIconMaterialKind.DatabaseArrowDownOutline, Operation = BackupOperation.RestoreFromDocuments },
        ];
        public BackupOperationOption[] BackupOperationOptions => backupOperationOptions;

        private Page? selectedPage = null;
        public Page? SelectedPage
        {
            get => selectedPage;
            set
            {
                if (Set(ref selectedPage, value))
                {
                    OnPropertyChanged(nameof(SummaryHeaderVisibility));
                }
            }
        }

        public Visibility SummaryHeaderVisibility => SelectedPage != null ? Visibility.Visible : Visibility.Collapsed;

        private bool isSplitViewPaneOpen = true;
        public bool IsSplitViewPaneOpen
        {
            get => isSplitViewPaneOpen;
            set => Set(ref isSplitViewPaneOpen, value);
        }

        public Summary Summary { get; } = new Summary();

        private readonly ICommand toggleSplitViewCommand;
        public ICommand ToggleSplitViewCommand => toggleSplitViewCommand;

        private readonly ICommand addPageCommand;
        public ICommand AddPageCommand => addPageCommand;

        private readonly ICommand setPageSortCommand;
        public ICommand SetPageSortCommand => setPageSortCommand;

        private readonly ICommand refreshPagesCommand;
        public ICommand RefreshPagesCommand => refreshPagesCommand;

        private readonly ICommand populateDefaultsCommand;
        public ICommand PopulateDefaultsCommand => populateDefaultsCommand;

        private readonly ICommand generateReportCommand;
        public ICommand GenerateReportCommand => generateReportCommand;

        private readonly ICommand startBackupOperationCommand;
        public ICommand StartBackupOperationCommand => startBackupOperationCommand;

        private readonly ICommand setThemeCommand;
        public ICommand SetThemeCommand => setThemeCommand;

        private readonly ICommand closePageCommand;
        public ICommand ClosePageCommand => closePageCommand;

        private readonly ICommand deletePageCommand;
        public ICommand DeletePageCommand => deletePageCommand;

        private Theme? theme = ThemeManager.Current.DetectTheme();
        public Theme? Theme
        {
            get => theme;
            set
            {
                if (Set(ref theme, value))
                {
                    if (Theme != null)
                    {
                        ThemeManager.Current.ChangeTheme(Application.Current, Theme);
                        UserSettings.StoreString("theme", Theme.Name);
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

        public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";

        private async void PopulateDefaultPages()
        {
            var singleFeaturePages = new[] {
                "abandoned",
                "abstract",
                "africa",
                "ai",
                "allblack",
                "allnature",
                "allsports",
                "alltrees",
                "allwhite",
                "architecture",
                "artgallery",
                "asia",
                "australia",
                "beaches",
                "birds",
                "blue",
                "bnw",
                "books",
                "bridges",
                "butterflies",
                "canada",
                "cats",
                "china",
                "cityscape",
                "cocktails",
                "coffee",
                "collage",
                "colorsplash",
                "colours",
                "community_member",
                "country",
                "cuteness",
                "depthoffield",
                "drone",
                "drops",
                "edit",
                "europe",
                "fishing",
                "flatlays",
                "flowers",
                "foggy",
                "france",
                "gardening",
                "germany",
                "herpetology",
                "hikes",
                "homestyle",
                "horses",
                "india",
                "insects",
                "ireland",
                "kitchen",
                "landscape",
                "lighthouses",
                "longexposure",
                "macro",
                "minimal",
                "mobile",
                "moody",
                "mountains",
                "nightshots",
                "nordic",
                "numbers",
                "oceanlife",
                "people",
                "pets",
                "potd",
                "reflection",
                "seasons",
                "silhouette",
                "skies",
                "street",
                "surreal",
                "symmetry",
                "tattoos",
                "thailand",
                "toys",
                "transports",
                "uae",
                "uk",
                "usa",
                "waters",
                "weddings",
                "wildlife",
                "world",
                "writings"
            };

            if (!await ShowConfirmationMessage(
                "Populate defaults",
                "Are you sure you want to remove all features and custom pages, this cannot be undone!"))
            {
                return;
            }

            SetBusy(true);
            StartOperation();

            foreach (var page in Pages)
            {
                RemoveModel(page);
            }
            Pages.Clear();

            foreach (var pageName in singleFeaturePages)
            {
                var page = new Page { Name = pageName };
                AddModel(page);
                Pages.Add(page);
            }

            var papaNoelPage = new Page { Name = "papanoel", Count = 3 };
            AddModel(papaNoelPage);
            Pages.Add(papaNoelPage);

            Pages.SortBy(pageSort);

            StopOperation(true);
            UpdateSummary();

            ShowToast("Populated the defaults", $"Populated {Pages.Count} default pages and challenges");
        }

        private int GetFeatures()
        {
            int count = 0;
            foreach (var page in Pages)
            {
                count += page.Features.Count;
            }
            return count;
        }

        private int GetTotalFeatures()
        {
            int count = 0;
            foreach (var page in Pages)
            {
                count += page.Features.Count * page.Count;
            }
            return count;
        }

        private int GetPages()
        {
            int count = 0;
            foreach (var page in Pages)
            {
                count += page.Features.Count != 0 ? 1 : 0;
            }
            return count;
        }

        private int GetTotalPages()
        {
            int count = 0;
            foreach (var page in Pages)
            {
                count += page.Features.Count != 0 ? page.Count : 0;
            }
            return count;
        }

        private static string GetStringForCount(int count, string baseString, string? pluralString = null)
        {
            if (count == 1)
            {
                return string.Format("{0} {1}", count, baseString);
            }
            if (string.IsNullOrEmpty(pluralString))
            {
                return string.Format("{0} {1}s", count, baseString);
            }
            return string.Format("{0} {1}", count, pluralString);
        }

        private string GetMembership()
        {
            var features = GetTotalFeatures();
            var pages = GetTotalPages();
            if (features < 5)
            {
                return "Artist";
            }
            if (features < 15)
            {
                return "Member";
            }
            if (pages < 15)
            {
                return "VIP Member";
            }
            if (pages < 35)
            {
                return "VIP Gold Member";
            }
            if (pages < 55)
            {
                return "Platinum Member";
            }
            if (pages < 80)
            {
                return "Elite Member";
            }
            return "Hall of Fame Member";
        }

        private void UpdateSummary()
        {
            var featuresCount = GetFeatures();
            var totalFeaturesCount = GetTotalFeatures();
            if (featuresCount != totalFeaturesCount)
            {
                Summary.Features = $"Total features: {featuresCount} (counts as {totalFeaturesCount})";
                Summary.ShortFeatures = $"Features: {featuresCount} ({totalFeaturesCount})";
            }
            else
            {
                Summary.Features = $"Total features: {featuresCount}";
                Summary.ShortFeatures = $"Features: {featuresCount}";
            }
            var pagesCount = GetPages();
            var totalPagesCount = GetTotalPages();
            if (pagesCount != totalPagesCount)
            {
                Summary.Pages = $"Total pages with features: {pagesCount} (counts as {totalPagesCount})";
                Summary.ShortPages = $"Pages: {pagesCount} ({totalPagesCount})";
            }
            else
            {
                Summary.Pages = $"Total pages with features: {pagesCount}";
                Summary.ShortPages = $"Pages: {pagesCount}";
            }
            Summary.Membership = $"Membership level: {GetMembership()}";
        }

        private void GenerateReport()
        {
            SetBusy(true);

            var builder = new StringBuilder();
            builder.AppendLine("Report of features");
            builder.AppendLine("------------------");
            builder.AppendLine();
            var featuresCount = GetFeatures();
            var totalFeaturesCount = GetTotalFeatures();
            if (featuresCount != totalFeaturesCount)
            {
                builder.AppendLine($"Total features: {featuresCount} (counts as {totalFeaturesCount})");
            }
            else
            {
                builder.AppendLine($"Total features: {featuresCount}");
            }
            builder.AppendLine();
            var pagesCount = GetPages();
            var totalPagesCount = GetTotalPages();
            if (pagesCount != totalPagesCount)
            {
                builder.AppendLine($"Total pages with features: {pagesCount} (counts as {totalPagesCount})");
            }
            else
            {
                builder.AppendLine($"Total pages with features: {pagesCount}");
            }
            builder.AppendLine();
            builder.AppendLine($"Membership level: {GetMembership()}");
            foreach (var page in Pages.OrderBy(page => page, PageComparer.FeaturesComparer))
            {
                if (page.Features.Count != 0)
                {
                    builder.AppendLine();
                    var pageType = page.IsChallenge ? "Challenge" : "Page";
                    if (page.Count != 1)
                    {
                        builder.AppendLine(
                            $"{pageType}: {page.Name.ToUpper()} - {GetStringForCount(page.Features.Count, "feature")} (counts as {page.Count * page.Features.Count})");
                    }
                    else
                    {
                        builder.AppendLine(
                            $"{pageType}: {page.Name.ToUpper()} - {GetStringForCount(page.Features.Count, "feature")}");
                    }
                    foreach (var feature in page.Features.OrderBy(feature => feature, FeatureComparer.DateComparer))
                    {
                        var hub = feature.Raw ? "RAW" : "Snap";
                        builder.AppendLine($"\tFeature: {feature.Date.ToLocalTime():D} on {hub}:");
                        builder.AppendLine($"\t\t{feature.Notes}");
                    }
                }
            }

            Clipboard.SetText(builder.ToString());

            ShowToast("Report generated", "Copied the report of features to the clipboard");
        }

        private void BackupToClipboard()
        {
            SetBusy(true);

            var jsonPages = Pages.OrderBy(page => page.Name).Select(page => page.ToJson());
            var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
            Clipboard.SetText(json);

            ShowToast("Backup complete", "Copied a backup of the pages and features to the clipboard");
        }

        private void BackupToDocuments()
        {
            var backupFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "FeatureTrackerBackup.json");
            SetBusy(true);

            var jsonPages = Pages.OrderBy(page => page.Name).Select(page => page.ToJson());
            var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
            File.WriteAllText(backupFilePath, json, Encoding.UTF8);

            ShowToast("Backup complete", "Copied a backup of the pages and features to your documents folder");
        }

        private async void RestoreFromClipboard()
        {
            if (Clipboard.ContainsText())
            {
                SetBusy(true);

                string json = Clipboard.GetText();
                try
                {
                    if (!await ShowConfirmationMessage(
                        "Restore from clipboard",
                        "Are you sure you want to reset all features and pages to the backup, this cannot be undone!"))
                    {
                        return;
                    }

                    var loadedPages = JsonConvert.DeserializeObject<List<JsonPage>>(json);
                    if (loadedPages != null)
                    {
                        StartOperation();
                        foreach (var page in Pages)
                        {
                            RemoveModel(page);
                        }
                        Pages.Clear();
                        foreach (var loadedPage in loadedPages)
                        {
                            var page = new Page(loadedPage);
                            AddModel(page);
                            Pages.Add(page);
                        }
                        Pages.SortBy(pageSort);
                        StopOperation(true);
                        UpdateSummary();

                        ShowToast("Restore complete", $"Restored {Pages.Count} pages and challenges from the clipboard");
                    }
                    else
                    {
                        ShowToast(
                            "Restore failed",
                            "Failed to restore from clipboard, there were no pages loaded",
                            NotificationType.Error,
                            TimeSpan.FromSeconds(5));
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine(ex.Message);
                    ShowToast(
                        "Restore failed",
                        "An error occurred restoring from clipboard, invalid data: " + ex.Message,
                        NotificationType.Error,
                        TimeSpan.FromSeconds(5));
                }
            }
            else
            {
                ShowToast(
                    "Restore failed",
                    "The clipboard did not include any text to restore",
                    NotificationType.Error,
                    TimeSpan.FromSeconds(5));
            }
        }

        private async void RestoreFromDocuments()
        {
            var backupFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "FeatureTrackerBackup.json");
            if (File.Exists(backupFilePath))
            {
                SetBusy(true);

                try
                {
                    if (!await ShowConfirmationMessage(
                        "Restore from documents folder",
                        "Are you sure you want to reset all features and pages to the backup, this cannot be undone!"))
                    {
                        return;
                    }

                    var json = File.ReadAllText(backupFilePath);
                    var loadedPages = JsonConvert.DeserializeObject<List<JsonPage>>(json);
                    if (loadedPages != null)
                    {
                        StartOperation();
                        foreach (var page in Pages)
                        {
                            RemoveModel(page);
                        }
                        Pages.Clear();
                        foreach (var loadedPage in loadedPages)
                        {
                            var page = new Page(loadedPage);
                            AddModel(page);
                            Pages.Add(page);
                        }
                        Pages.SortBy(pageSort);
                        StopOperation(true);

                        ShowToast("Restore complete", $"Restored {Pages.Count} pages and challenges from the clipboard");
                    }
                    else
                    {
                        ShowToast(
                            "Restore failed",
                            "Failed to restore from clipboard, there were no pages loaded",
                            NotificationType.Error,
                            TimeSpan.FromSeconds(5));
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine(ex.Message);
                    ShowToast(
                        "Restore failed",
                        "An error occurred restoring from clipboard, invalid data: " + ex.Message,
                        NotificationType.Error,
                        TimeSpan.FromSeconds(5));
                }
            }
            else
            {
                ShowToast(
                    "Restore failed",
                    "Could not find the backup file in your documents folder",
                    NotificationType.Error,
                    TimeSpan.FromSeconds(5));
            }
        }

        private void OnModelChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (sender is Model model)
            {
                if (model.ModelProperties.Contains(e.PropertyName))
                {
                    // TODO trigger debouncer to save data...
                    if (operationCount == 0)
                    {
                        Debug.WriteLine("Saving data from model changed...");
                        StorePages();
                    }
                    model.OnDataChanged(e.PropertyName);
                }
            }
        }

        public void AddModel(Model model)
        {
            model.PropertyChanged += OnModelChanged;
            model.DataManager = this;
            UpdateSummary();
        }

        public void RemoveModel(Model model)
        {
            model.DataManager = null;
            model.PropertyChanged -= OnModelChanged;
            UpdateSummary();
        }

        private void OnModelCollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            // TODO trigger debouncer to save data...
            if (operationCount == 0)
            {
                Debug.WriteLine("Saving data from collection changed...");
                StorePages();
                UpdateSummary();
            }
        }

        public void AddModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged += OnModelCollectionChanged;
            UpdateSummary();
        }

        public void RemoveModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged -= OnModelCollectionChanged;
            UpdateSummary();
        }

        public void StartOperation()
        {
            ++operationCount;
        }

        public void StopOperation(bool saveData = false)
        {
            --operationCount;
            if (saveData && operationCount == 0)
            {
                StorePages();
            }
        }

        internal void ResetTheme(Theme theme)
        {
            Theme = theme;
        }
    }

    public class Page : EditableModel
    {
        public Page()
        {
            refreshFeaturesCommand = new Command(() =>
            {
                RefreshFeatures();
            });
            addFeatureCommand = new Command(() =>
            {
                var feature = new Feature() { Date = DateTime.Now };
                DataManager?.AddModel(feature);
                Features.Add(feature);
                SelectedFeature = feature;
            });
            closeFeatureCommand = new Command(() => SelectedFeature = null);
            deleteFeatureCommand = new Command(async () =>
            {
                if (!await MainViewModel.ShowConfirmationMessage(
                    "Delete feature",
                    "Are you sure you want to delete this feature, this cannot be undone!"))
                {
                    return;
                }
                var feature = SelectedFeature;
                SelectedFeature = null;
                if (feature != null)
                {
                    Features.Remove(feature);
                    DataManager?.RemoveModel(feature);
                }
                DataManager?.ShowToast("Deleted feature", "Removed the page or challenge and all the features", NotificationType.Notification);
            });
            Features.CollectionChanged += (sender, e) =>
            {
                FontWeight = Features.Count > 0 ? FontWeights.SemiBold : FontWeights.Light;
                AlternativeTitle = (Count > 1) ? $"({Features.Count} x {Count})" : $"({Features.Count})";
                OnPropertyChanged(nameof(FeaturesCount));
            };
            Title = Name.ToUpper();
            FontWeight = Features.Count > 0 ? FontWeights.SemiBold : FontWeights.Light;
            AlternativeTitle = (Count > 1) ? $"({Features.Count} x {Count})" : $"({Features.Count})";
            IconKind = IsChallenge ? PackIconModernKind.Calendar : PackIconModernKind.Page;
            EditorPageFactory = (parameter) => new PageEditor(parameter as MainViewModel);
        }

        public Page(JsonPage jsonPage) : this()
        {
            Id = jsonPage.Id;
            Name = jsonPage.Name;
            Notes = jsonPage.Notes;
            Count = jsonPage.Count;
            IsChallenge = jsonPage.IsChallenge;
            foreach (var jsonFeature in jsonPage.Features)
            {
                var feature = new Feature(jsonFeature);
                Features.Add(feature);
            }
        }

        public JsonPage ToJson()
        {
            return new JsonPage
            {
                Id = Id,
                Name = Name,
                Notes = Notes,
                Count = Count,
                IsChallenge = IsChallenge,
                Features = new List<JsonFeature>(Features.Select(feature => feature.ToJson()))
            };
        }

        public SortableModelCollection<Feature> Features { get; } = [];

        private void RefreshFeatures()
        {
            MainViewModel.SetBusy(true);
            DataManager?.StartOperation();
            var oldSelectedFeature = SelectedFeature;
            SelectedFeature = null;
            Features.SortBy(FeatureComparer.DateComparer);
            DataManager?.StopOperation();
            SelectedFeature = oldSelectedFeature;
        }

        public string FeaturesCount
        {
            get
            {
                var suffix = Features.Count != 1 ? "s" : "";
                return $"{Features.Count} feature{suffix}";
            }
        }

        private Feature? selectedFeature = null;
        public Feature? SelectedFeature
        {
            get => selectedFeature;
            set => Set(ref selectedFeature, value);
        }

        public Guid Id { get; private set; }

        private string name = "";
        public string Name
        {
            get => name;
            set
            {
                if (Set(ref name, value))
                {
                    Title = Name.ToUpper();
                }
            }
        }

        private string notes = "";
        public string Notes
        {
            get => notes;
            set => Set(ref notes, value);
        }

        private int count = 1;
        public int Count
        {
            get => count;
            set
            {
                if (Set(ref count, value))
                {
                    AlternativeTitle = (Count > 1) ? $"({Features.Count} x {Count})" : $"({Features.Count})";
                }
            }
        }

        private bool isChallenge = false;
        public bool IsChallenge
        {
            get => isChallenge;
            set
            {
                if (Set(ref isChallenge, value))
                {
                    IconKind = IsChallenge ? PackIconModernKind.Calendar : PackIconModernKind.Page;
                }
            }
        }

        private readonly ICommand addFeatureCommand;
        public ICommand AddFeatureCommand => addFeatureCommand;

        private readonly ICommand refreshFeaturesCommand;
        public ICommand RefreshFeaturesCommand => refreshFeaturesCommand;

        private readonly ICommand closeFeatureCommand;
        public ICommand CloseFeatureCommand => closeFeatureCommand;

        private readonly ICommand deleteFeatureCommand;
        public ICommand DeleteFeatureCommand => deleteFeatureCommand;

        public override string[] ModelProperties => [nameof(Name), nameof(Notes), nameof(Count), nameof(IsChallenge)];

        public override string[] ModelCollectionProperties => [nameof(Features)];

        private IDataManager? dataManager;
        public override IDataManager? DataManager
        {
            get => dataManager;
            set
            {
                if (dataManager != null)
                {
                    foreach (var feature in Features)
                    {
                        dataManager.RemoveModel(feature);
                    }
                    dataManager.RemoveModelCollection(Features);
                }
                dataManager = value;
                if (dataManager != null)
                {
                    dataManager.AddModelCollection(Features);
                    foreach (var feature in Features)
                    {
                        dataManager.AddModel(feature);
                    }
                }
            }
        }
    }

    public class Feature : EditableModel
    {
        public Feature()
        {
            Id = Guid.NewGuid();
            Title = Date.ToString("D");
            AlternativeTitle = Raw ? "RAW" : "";
            SubTitle = Notes;
            EditorPageFactory = (parameter) => new FeatureEditor(parameter as MainViewModel);
        }

        public Feature(JsonFeature jsonFeature) : this()
        {
            Id = jsonFeature.Id;
            Date = jsonFeature.Date;
            Raw = jsonFeature.Raw;
            Notes = jsonFeature.Notes;
        }

        public JsonFeature ToJson()
        {
            return new JsonFeature
            {
                Id = Id,
                Date = Date,
                Raw = Raw,
                Notes = Notes,
            };
        }

        public Guid Id { get; private set; }

        private DateTime date = DateTime.Now;
        public DateTime Date
        {
            get => date;
            set
            {
                if (Set(ref date, value))
                {
                    Title = Date.ToString("D");
                }
            }
        }

        private bool raw = false;
        public bool Raw
        {
            get => raw;
            set
            {
                if (Set(ref raw, value))
                {
                    AlternativeTitle = Raw ? "RAW" : "";
                }
            }
        }

        private string notes = "";
        public string Notes
        {
            get => notes;
            set
            {
                if (Set(ref notes, value))
                {
                    SubTitle = Notes;
                }
            }
        }

        public override string[] ModelProperties => [nameof(Date), nameof(Notes), nameof(Raw)];

        public override string[] ModelCollectionProperties => [];

        public override IDataManager? DataManager { get; set; }
    }

    public class JsonPage
    {
        [JsonProperty(PropertyName = "count")]
        public int Count { get; set; } = 1;

        [JsonProperty(PropertyName = "features", NullValueHandling = NullValueHandling.Ignore)]
        public IList<JsonFeature> Features { get; set; } = [];

        [JsonProperty(PropertyName = "id"), JsonConverter(typeof(UppercaseGuidConverter))]
        public Guid Id { get; set; } = Guid.NewGuid();

        [JsonProperty(PropertyName = "isChallenge")]
        public bool IsChallenge { get; set; } = false;

        [JsonProperty(PropertyName = "name")]
        public string Name { get; set; } = "";

        [JsonProperty(PropertyName = "notes")]
        public string Notes { get; set; } = "";
    }

    public class JsonFeature
    {
        [JsonProperty(PropertyName = "dateV2")]
        public DateTime Date { get; set; } = DateTime.Now;

        [JsonProperty(PropertyName = "id"), JsonConverter(typeof(UppercaseGuidConverter))]
        public Guid Id { get; set; } = Guid.NewGuid();

        [JsonProperty(PropertyName = "notes")]
        public string Notes { get; set; } = "";

        [JsonProperty(PropertyName = "raw")]
        public bool Raw { get; set; } = false;
    }

    public class UppercaseGuidConverter : JsonConverter<Guid>
    {
        public override void WriteJson(JsonWriter writer, Guid value, JsonSerializer serializer)
        {
            writer.WriteValue(value.ToString("D").ToUpper());
        }

        public override Guid ReadJson(JsonReader reader, Type objectType, Guid existingValue, bool hasExistingValue, JsonSerializer serializer)
        {
            return new Guid((reader.Value as string) ?? "");
        }
    }

    public class SortOption<T>: NotifyPropertyChanged where T : Model
    {
        public IComparer<T>? Comparer { get; set; }

        public string? Label { get; set; }

        private bool isSelected = false;
        public bool IsSelected 
        { 
            get => isSelected;
            set => Set(ref isSelected, value);
        }

        public int CompareMode { get; set; }
    }

    public enum BackupOperation
    {
        BackupToClipboard,
        BackupToDocuments,
        RestoreFromClipboard,
        RestoreFromDocuments,
    }

    public class BackupOperationOption
    {
        public string? Label { get; set; }

        public PackIconMaterialKind IconKind { get; set; }

        public BackupOperation Operation { get; set; }
    }

    public class ThemeOption(Theme theme, bool isSelected = false)
    {
        public Theme Theme { get; } = theme;

        public bool IsSelected { get; } = isSelected;
    }

    public class Summary : NotifyPropertyChanged
    {
        private string? features;
        public string? Features
        {
            get => features;
            set => Set(ref features, value);
        }

        private string? pages;
        public string? Pages
        {
            get => pages;
            set => Set(ref pages, value);
        }

        private string? membership;
        public string? Membership
        {
            get => membership;
            set => Set(ref membership, value);
        }

        private string? shortFeatures;
        public string? ShortFeatures
        {
            get => shortFeatures;
            set => Set(ref shortFeatures, value);
        }

        private string? shortPages;
        public string? ShortPages
        {
            get => shortPages;
            set => Set(ref shortPages, value);
        }
    }
}
