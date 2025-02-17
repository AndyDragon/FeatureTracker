using ControlzEx.Theming;
using MahApps.Metro.Controls.Dialogs;
using MahApps.Metro.IconPacks;
using Microsoft.Win32;
using Newtonsoft.Json;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;

namespace FeatureTracker
{
    public class MainViewModel : NotifyPropertyChanged, IDataManager
    {
        private int operationCount = 0;

        public MainViewModel()
        {
            ToggleSplitViewCommand = new Command(() => this.IsSplitViewPaneOpen = !this.IsSplitViewPaneOpen);
            AddPageCommand = new Command(() =>
            {
                var page = new Page() { Name = "new page", Hub = "" };
                AddModel(page);
                Pages.Add(page);
                SelectedPage = page;
            });
            SetPageSortCommand = new CommandWithParameter((parameter) =>
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
            RefreshPagesCommand = new Command(RefreshPages);
            PopulateDefaultsCommand = new Command(PopulateDefaultPages);
            GenerateReportCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is EntryForReport entryForReport && entryForReport.Type != EntryType.Separator)
                {
                    switch (entryForReport.Type)
                    {
                        case EntryType.Hub:
                            GenerateReportForHub(entryForReport.Entry!);
                            break;

                        case EntryType.Page:
                            GenerateReportForPage(entryForReport.Entry!);
                            break;
                    }
                }
            }, (parameter) => parameter is EntryForReport entryForReport && entryForReport.Type != EntryType.Separator);
            StartBackupOperationCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is BackupOperation operation && operation != BackupOperation.Separator)
                {
                    switch (operation)
                    {
                        case BackupOperation.BackupToClipboard:
                            BackupToClipboard();
                            break;
                        case BackupOperation.BackupToFile:
                            BackupToFile();
                            break;
                        case BackupOperation.BackupToDocuments:
                            BackupToDocuments();
                            break;
                        case BackupOperation.RestoreFromClipboard:
                            RestoreFromClipboard();
                            break;
                        case BackupOperation.RestoreFromFile:
                            RestoreFromFile();
                            break;
                        case BackupOperation.RestoreFromDocuments:
                            RestoreFromDocuments();
                            break;
                    }
                }
            }, (parameter) => parameter is BackupOperation operation && operation != BackupOperation.Separator);
            SetThemeCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is Theme theme)
                {
                    Theme = theme;
                }
            });
            ClosePageCommand = new Command(() => SelectedPage = null);
            DeletePageCommand = new Command(async () =>
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
            LaunchAboutCommand = new Command(() =>
            {
                var panel = new AboutDialog
                {
                    DataContext = new AboutViewModel(),
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
                panel.ShowDialog();
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
            foreach (var pageSortOption in PageSortOptions)
            {
                pageSortOption.IsSelected = pageSortOption.Comparer == pageSort;
            }
            OnPropertyChanged(nameof(PageSortOptions));
            UpdateSummary(SelectedPage);
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
                            UpdateSummary(SelectedPage);
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

        public string[] HubsWithFeatures
        {
            get
            {
                var hubs = new Dictionary<string, bool>();
                foreach (var page in Pages)
                {
                    if (!string.IsNullOrEmpty(page.Hub) && page.Features.Count != 0)
                    {
                        hubs[page.Hub] = true;
                    }
                }
                return [.. hubs.Keys];
            }
        }

        public string[] PagesWithFeatures
        {
            get
            {
                var pages = new Dictionary<string, bool>();
                foreach (var page in Pages)
                {
                    if (string.IsNullOrEmpty(page.Hub) && page.Features.Count != 0)
                    {
                        pages[page.Name] = true;
                    }
                }
                return [.. pages.Keys];
            }
        }

        public EntryForReport[] EntriesForReports
        {
            get
            {
                var list = new List<EntryForReport>();
                list.AddRange(HubsWithFeatures.Order().Select(hub => new EntryForReport
                {
                    IconKind = PackIconMaterialKind.Book,
                    Label = $"Generate report for {hub.ToLower()}",
                    Type = EntryType.Hub,
                    Entry = hub,
                }));
                list.Add(new SeparatorEntryForReport());
                list.AddRange(PagesWithFeatures.Order().Select(page => new EntryForReport
                {
                    IconKind = PackIconMaterialKind.BookOutline,
                    Label = $"Generate report for {page.ToLower()}",
                    Type = EntryType.Page,
                    Entry = page,
                }));
                return [.. list];
            }
        }

        private void StorePages()
        {
            try
            {
                var dataPath = GetDataPath();
                var jsonPages = Pages.Select(page => page.ToJson()).OrderBy(page => (page.Hub + "_" + page.Name).ToLower());
                var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
                File.WriteAllText(dataPath, json);
                OnPropertyChanged(nameof(EntriesForReports));
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
            foreach (var pageSortOption in PageSortOptions)
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

            return Application.Current?.MainWindow is MahApps.Metro.Controls.MetroWindow mainWindow
                ? (await mainWindow.ShowMessageAsync(
                    title,
                    message,
                    MessageDialogStyle.AffirmativeAndNegative,
                    settings)) == MessageDialogResult.Affirmative
                : MessageBox.Show(
                    message,
                    title,
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question) == MessageBoxResult.Yes;
        }

        private readonly NotificationManager notificationManager = new();

        public SortableModelCollection<Page> Pages { get; } = [];

        private PageComparer pageSort = PageComparer.NameComparer;

        public SortOption<Page>[] PageSortOptions { get; } = [
            new SortOption<Page> { Comparer = PageComparer.NameComparer, Label = "Sort by Name", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Name },
            new SortOption<Page> { Comparer = PageComparer.CountComparer, Label = "Sort by Count", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Count },
            new SortOption<Page> { Comparer = PageComparer.FeaturesComparer, Label = "Sort by Features", IsSelected = false, CompareMode = (int)PageComparer.CompareMode.Features },
        ];

        public BackupOperationOption[] BackupOperationOptions { get; } = [
            new BackupOperationOption { Label = "Backup to Clipboard", IconKind = PackIconMaterialKind.ClipboardArrowUpOutline, Operation = BackupOperation.BackupToClipboard },
            new BackupOperationOption { Label = "Backup to File", IconKind = PackIconMaterialKind.BookArrowUpOutline, Operation = BackupOperation.BackupToFile },
            new BackupOperationOption { Label = "Backup to Documents", IconKind = PackIconMaterialKind.DatabaseArrowUpOutline, Operation = BackupOperation.BackupToDocuments },
            new SeparatorBackupOperationOption(),
            new BackupOperationOption { Label = "Restore from Clipboard", IconKind = PackIconMaterialKind.ClipboardArrowDownOutline, Operation = BackupOperation.RestoreFromClipboard },
            new BackupOperationOption { Label = "Restore from File", IconKind = PackIconMaterialKind.BookArrowDownOutline, Operation = BackupOperation.RestoreFromFile },
            new BackupOperationOption { Label = "Restore from Documents", IconKind = PackIconMaterialKind.DatabaseArrowDownOutline, Operation = BackupOperation.RestoreFromDocuments },
        ];

        private Page? selectedPage = null;
        public Page? SelectedPage
        {
            get => selectedPage;
            set
            {
                if (Set(ref selectedPage, value))
                {
                    OnPropertyChanged(nameof(SummaryHeaderVisibility));
                    UpdateSummary(SelectedPage);
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
        public ICommand ToggleSplitViewCommand { get; }

        public ICommand AddPageCommand { get; }

        public ICommand SetPageSortCommand { get; }

        public ICommand RefreshPagesCommand { get; }

        public ICommand PopulateDefaultsCommand { get; }

        public ICommand GenerateReportCommand { get; }

        public ICommand StartBackupOperationCommand { get; }

        public ICommand SetThemeCommand { get; }

        public ICommand ClosePageCommand { get; }

        public ICommand DeletePageCommand { get; }

        public ICommand LaunchAboutCommand { get; }

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
                        OnPropertyChanged(nameof(StatusBarBrush));
                        OnPropertyChanged(nameof(Themes));
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

        public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";

        private bool windowActive = false;
        public bool WindowActive
        {
            get => windowActive;
            set
            {
                if (Set(ref windowActive, value))
                {
                    OnPropertyChanged(nameof(StatusBarBrush));
                }
            }
        }

        public Brush? StatusBarBrush => WindowActive
            ? Theme?.Resources["MahApps.Brushes.Accent2"] as Brush
            : Theme?.Resources["MahApps.Brushes.WindowTitle.NonActive"] as Brush;

        private async void PopulateDefaultPages()
        {
            var singleFeaturePagesForSnap = new[] {
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

            foreach (var pageName in singleFeaturePagesForSnap)
            {
                var page = new Page { Name = pageName, Hub = "snap" };
                AddModel(page);
                Pages.Add(page);
            }

            var papaNoelPage = new Page { Name = "papanoel", Hub = "snap", Count = 3 };
            AddModel(papaNoelPage);
            Pages.Add(papaNoelPage);

            var singleFeaturePagesForClick = new[] {
                "astro",
                "dogs",
                "machines"
            };

            foreach (var pageName in singleFeaturePagesForClick)
            {
                var page = new Page { Name = pageName, Hub = "click" };
                AddModel(page);
                Pages.Add(page);
            }

            var singleFeaturePagesForPodium = new[] {
                "podium",
                "macro",
                "mono",
                "night",
                "portraits",
                "street",
                "wildlife",
            };

            foreach (var pageName in singleFeaturePagesForPodium)
            {
                var page = new Page { Name = pageName, Hub = "podium" };
                AddModel(page);
                Pages.Add(page);
            }

            Pages.SortBy(pageSort);

            StopOperation(true);
            UpdateSummary(SelectedPage);

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

        private int GetFeatures(string hub)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (page.Hub.Equals(hub, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count;
                }
            }
            return count;
        }

        private int GetFeaturesForPage(string lonePage)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (string.IsNullOrEmpty(page.Hub) && page.Name.Equals(lonePage, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count;
                }
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

        private int GetTotalFeatures(string hub)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (page.Hub.Equals(hub, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count * page.Count;
                }
            }
            return count;
        }

        private int GetTotalFeaturesForPage(string lonePage)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (string.IsNullOrEmpty(page.Hub) && page.Name.Equals(lonePage, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count * page.Count;
                }
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

        private int GetPages(string hub)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (page.Hub.Equals(hub, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count != 0 ? 1 : 0;
                }
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

        private int GetTotalPages(string hub)
        {
            int count = 0;
            foreach (var page in Pages)
            {
                if (page.Hub.Equals(hub, StringComparison.CurrentCultureIgnoreCase))
                {
                    count += page.Features.Count != 0 ? page.Count : 0;
                }
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

        private string GetMembership(string hub)
        {
            var features = GetTotalFeatures(hub);
            var pages = GetTotalPages(hub);
            if (hub == "snap")
            {
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
            if (hub == "click")
            {
                if (features < 5)
                {
                    return "Artist";
                }
                if (features < 15)
                {
                    return "Bronze member";
                }
                if (features < 30)
                {
                    return "Silver Member";
                }
                if (features < 50)
                {
                    return "Gold Member";
                }
                return "Platinum Member";
            }
            return "Artist";
        }

        private void UpdateSummary(Page? page)
        {
            if (page != null)
            {
                if (!string.IsNullOrEmpty(page.Hub))
                {
                    var featuresCount = GetFeatures(page.Hub);
                    var totalFeaturesCount = GetTotalFeatures(page.Hub);
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
                    var pagesCount = GetPages(page.Hub);
                    var totalPagesCount = GetTotalPages(page.Hub);
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
                    if (HasMembershipLevels(page.Hub))
                    {
                        Summary.Membership = $"Membership level: {GetMembership(page.Hub)}";
                    }
                    else
                    {
                        Summary.Membership = "";
                    }
                }
                else
                {
                    var featuresCount = GetFeaturesForPage(page.Name);
                    var totalFeaturesCount = GetTotalFeaturesForPage(page.Name);
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
                    Summary.Pages = "";
                    Summary.ShortPages = "";
                    Summary.Membership = "";
                }
            }
            else
            {
                Summary.HubSummaries.Clear();
                var globalFeaturesCount = GetFeatures();
                var globalTotalFeaturesCount = GetTotalFeatures();
                var totalSummary = new HubSummary();
                if (globalFeaturesCount != globalTotalFeaturesCount)
                {
                    totalSummary.Features = $"Total features: {globalFeaturesCount} (counts as {globalTotalFeaturesCount})";
                }
                else
                {
                    totalSummary.Features = $"Total features: {globalFeaturesCount}";
                }
                Summary.HubSummaries.Add(totalSummary);

                var hubs = HubsWithFeatures;
                foreach (var hub in hubs.OrderBy(hub => GetFeatures(hub)).Reverse())
                {
                    var hubSummary = new HubSummary()
                    {
                        Hub = hub
                    };
                    var featuresCount = GetFeatures(hub);
                    var totalFeaturesCount = GetTotalFeatures(hub);
                    if (featuresCount != totalFeaturesCount)
                    {
                        hubSummary.Features = $"Total features: {featuresCount} (counts as {totalFeaturesCount})";
                    }
                    else
                    {
                        hubSummary.Features = $"Total features: {featuresCount}";
                    }
                    var pagesCount = GetPages(hub);
                    var totalPagesCount = GetTotalPages(hub);
                    if (pagesCount != totalPagesCount)
                    {
                        hubSummary.Pages = $"Total pages with features: {pagesCount} (counts as {totalPagesCount})";
                    }
                    else
                    {
                        hubSummary.Pages = $"Total pages with features: {pagesCount}";
                    }
                    if (HasMembershipLevels(hub))
                    {
                        hubSummary.Membership = $"Membership level: {GetMembership(hub)}";
                    }
                    else
                    {
                        hubSummary.Membership = "";
                    }
                    Summary.HubSummaries.Add(hubSummary);
                }
            }
        }

        private void GenerateReportForHub(string hub)
        {
            SetBusy(true);

            var builder = new StringBuilder();
            builder.AppendLine("Report of features for " + hub.Capitalize());
            builder.AppendLine(new string('-', 23 + hub.Length));
            builder.AppendLine();
            var featuresCount = GetFeatures(hub);
            var totalFeaturesCount = GetTotalFeatures(hub);
            if (featuresCount != totalFeaturesCount)
            {
                builder.AppendLine($"Total features: {featuresCount} (counts as {totalFeaturesCount})");
            }
            else
            {
                builder.AppendLine($"Total features: {featuresCount}");
            }
            builder.AppendLine();
            var pagesCount = GetPages(hub);
            var totalPagesCount = GetTotalPages(hub);
            if (pagesCount != totalPagesCount)
            {
                builder.AppendLine($"Total pages with features: {pagesCount} (counts as {totalPagesCount})");
            }
            else
            {
                builder.AppendLine($"Total pages with features: {pagesCount}");
            }
            if (HasMembershipLevels(hub))
            {
                builder.AppendLine();
                builder.AppendLine($"Membership level: {GetMembership(hub)}");
            }
            foreach (var page in Pages.Where(page => string.Equals(page.Hub, hub, StringComparison.OrdinalIgnoreCase)).OrderBy(page => page, PageComparer.FeaturesComparer))
            {
                if (page.Features.Count != 0)
                {
                    builder.AppendLine();
                    var pageType = page.IsChallenge ? "Challenge" : "Page";
                    if (page.Count != 1)
                    {
                        builder.AppendLine(
                            $"{pageType}: {page.Name.ToLower()} - {GetStringForCount(page.Features.Count, "feature")} (counts as {page.Count * page.Features.Count})");
                    }
                    else
                    {
                        builder.AppendLine(
                            $"{pageType}: {page.Name.ToLower()} - {GetStringForCount(page.Features.Count, "feature")}");
                    }
                    foreach (var feature in page.Features.OrderBy(feature => feature, FeatureComparer.DateComparer))
                    {
                        if (hub == "snap")
                        {
                            var rawHub = feature.Raw ? " [RAW]" : "";
                            builder.AppendLine($"    Feature: {feature.Date.ToLocalTime():D}{rawHub} - {feature.Notes}");
                        }
                        else
                        {
                            builder.AppendLine($"    Feature: {feature.Date.ToLocalTime():D} - {feature.Notes}");
                        }
                    }
                }
            }

            Clipboard.SetText(builder.ToString());

            ShowToast("Report generated", $"Copied the report of features to the clipboard for the {hub.Capitalize()} hub");
        }

        private void GenerateReportForPage(string lonePage)
        {
            SetBusy(true);

            var builder = new StringBuilder();
            builder.AppendLine("Report of features for " + lonePage.ToLower());
            builder.AppendLine(new string('-', 23 + lonePage.Length));
            builder.AppendLine();
            var featuresCount = GetFeaturesForPage(lonePage);
            var totalFeaturesCount = GetTotalFeaturesForPage(lonePage);
            if (featuresCount != totalFeaturesCount)
            {
                builder.AppendLine($"Total features: {featuresCount} (counts as {totalFeaturesCount})");
            }
            else
            {
                builder.AppendLine($"Total features: {featuresCount}");
            }
            builder.AppendLine();
            var page = Pages.FirstOrDefault(p => string.IsNullOrEmpty(p.Hub) && p.Name.Equals(lonePage, StringComparison.CurrentCultureIgnoreCase));
            if (page != null)
            {
                if (page.Features.Count != 0)
                {
                    foreach (var feature in page.Features.OrderBy(feature => feature, FeatureComparer.DateComparer))
                    {
                        builder.AppendLine($"Feature: {feature.Date.ToLocalTime():D} - {feature.Notes}");
                    }
                }
            }

            Clipboard.SetText(builder.ToString());

            ShowToast("Report generated", $"Copied the report of features to the clipboard for the {lonePage.ToLower()} page");
        }

        private static bool HasMembershipLevels(string hub)
        {
            return hub == "snap" || hub == "click";
        }

        private void BackupToClipboard()
        {
            SetBusy(true);

            var jsonPages = Pages.OrderBy(page => page.OptionalHubAndName.ToLower()).Select(page => page.ToJson());
            var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
            Clipboard.SetText(json);

            ShowToast("Backup complete", "Copied a backup of the pages and features to the clipboard");
        }

        private void BackupToFile()
        {
            SaveFileDialog dialog = new()
            {
                Filter = "Backup files (*.json)|*.json|All files (*.*)|*.*",
                Title = "Backup the pages and features to a backup file",
                OverwritePrompt = true,
                FileName = $"Feature Tracker backup - {DateTime.Now:yyyy-MM-dd}",
            };
            if (dialog.ShowDialog() == true)
            {
                SetBusy(true);

                var jsonPages = Pages.OrderBy(page => page.OptionalHubAndName.ToLower()).Select(page => page.ToJson());
                var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
                File.WriteAllText(dialog.FileName, json, Encoding.UTF8);

                ShowToast("Backup complete", "Copied a backup of the pages and features to the file");
            }
        }

        private void BackupToDocuments()
        {
            var backupFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "FeatureTrackerBackup.json");
            SetBusy(true);

            var jsonPages = Pages.OrderBy(page => page.OptionalHubAndName.ToLower()).Select(page => page.ToJson());
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
                        UpdateSummary(SelectedPage);

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

        private async void RestoreFromFile()
        {
            OpenFileDialog dialog = new()
            {
                Filter = "Backup files (*.json)|*.json|All files (*.*)|*.*",
                Title = "Restore the pages and features from a backup file",
                CheckFileExists = true
            };
            if (dialog.ShowDialog() == true)
            {
                if (File.Exists(dialog.FileName))
                {
                    SetBusy(true);

                    try
                    {
                        if (!await ShowConfirmationMessage(
                            "Restore from file",
                            "Are you sure you want to reset all features and pages to the backup, this cannot be undone!"))
                        {
                            return;
                        }

                        var json = File.ReadAllText(dialog.FileName);
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

                            ShowToast("Restore complete", $"Restored {Pages.Count} pages and challenges from the file");
                        }
                        else
                        {
                            ShowToast(
                                "Restore failed",
                                "Failed to restore from file, there were no pages loaded",
                                NotificationType.Error,
                                TimeSpan.FromSeconds(5));
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.WriteLine(ex.Message);
                        ShowToast(
                            "Restore failed",
                            "An error occurred restoring from file, invalid data: " + ex.Message,
                            NotificationType.Error,
                            TimeSpan.FromSeconds(5));
                    }
                }
                else
                {
                    ShowToast(
                        "Restore failed",
                        "Could not find the backup file",
                        NotificationType.Error,
                        TimeSpan.FromSeconds(5));
                }
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

                        ShowToast("Restore complete", $"Restored {Pages.Count} pages and challenges from your documents folder");
                    }
                    else
                    {
                        ShowToast(
                            "Restore failed",
                            "Failed to restore from your documents folder, there were no pages loaded",
                            NotificationType.Error,
                            TimeSpan.FromSeconds(5));
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine(ex.Message);
                    ShowToast(
                        "Restore failed",
                        "An error occurred restoring from your documents folder, invalid data: " + ex.Message,
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
            UpdateSummary(SelectedPage);
        }

        public void RemoveModel(Model model)
        {
            model.DataManager = null;
            model.PropertyChanged -= OnModelChanged;
            UpdateSummary(SelectedPage);
        }

        private void OnModelCollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            // TODO trigger debouncer to save data...
            if (operationCount == 0)
            {
                Debug.WriteLine("Saving data from collection changed...");
                StorePages();
                UpdateSummary(SelectedPage);
            }
        }

        public void AddModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged += OnModelCollectionChanged;
            UpdateSummary(SelectedPage);
        }

        public void RemoveModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged -= OnModelCollectionChanged;
            UpdateSummary(SelectedPage);
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
            RefreshFeaturesCommand = new Command(RefreshFeatures);
            AddFeatureCommand = new Command(() =>
            {
                var feature = new Feature() { Date = DateTime.Now };
                DataManager?.AddModel(feature);
                Features.Add(feature);
                SelectedFeature = feature;
            });
            CloseFeatureCommand = new Command(() => SelectedFeature = null);
            DeleteFeatureCommand = new Command(async () =>
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
            Id = Guid.NewGuid();
            Title = OptionalHubAndName;
            FontWeight = Features.Count > 0 ? FontWeights.SemiBold : FontWeights.Light;
            AlternativeTitle = (Count > 1) ? $"({Features.Count} x {Count})" : $"({Features.Count})";
            IconKind = IsChallenge ? PackIconModernKind.Calendar : PackIconModernKind.Page;
            EditorPageFactory = (parameter) => new PageEditor(parameter as MainViewModel);
        }

        public Page(JsonPage jsonPage) : this()
        {
            Id = jsonPage.Id;
            Name = jsonPage.Name;
            Hub = jsonPage.Hub;
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
                Hub = Hub,
                Notes = Notes,
                Count = Count,
                IsChallenge = IsChallenge,
                Features = [.. Features.Select(feature => feature.ToJson())]
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

        public string HubAndName => $"{Hub}_{Name}".ToUpper();
        public string OptionalHubAndName
        {
            get
            {
                if (string.IsNullOrEmpty(Hub) || string.Equals(Hub, Name, StringComparison.OrdinalIgnoreCase))
                {
                    return Name.ToUpper();
                }
                return $"{Hub}_{Name}".ToUpper();
            }
        }

        private string name = "";
        public string Name
        {
            get => name;
            set
            {
                if (Set(ref name, value))
                {
                    Title = OptionalHubAndName;
                }
            }
        }

        private string hub = "";
        public string Hub
        {
            get => hub;
            set
            {
                if (Set(ref hub, value))
                {
                    Title = OptionalHubAndName;
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

        public ICommand AddFeatureCommand { get; }

        public ICommand RefreshFeaturesCommand { get; }

        public ICommand CloseFeatureCommand { get; }

        public ICommand DeleteFeatureCommand { get; }

        public override string[] ModelProperties => [nameof(Name), nameof(Hub), nameof(Notes), nameof(Count), nameof(IsChallenge)];

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

        [JsonProperty(PropertyName = "hub")]
        public string Hub { get; set; } = "snap";

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

    public class SortOption<T> : NotifyPropertyChanged where T : Model
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

    public enum EntryType
    {
        Separator,
        Hub,
        Page,
    }

    public class OptionBaseItem
    {
        public PackIconMaterialKind IconKind { get; set; }

        public string? Label { get; set; }
    }

    public class EntryForReport : OptionBaseItem
    {
        public EntryType Type { get; set; }

        public string? Entry { get; set; }
    }

    public class SeparatorEntryForReport : EntryForReport { }

    public class EntryForReportTemplateSelector : DataTemplateSelector
    {
        public DataTemplate? EntryForReportTemplate { get; set; }
        public DataTemplate? SeparatorTemplate { get; set; }

        public override DataTemplate SelectTemplate(object item, DependencyObject container)
        {
            if (item is SeparatorEntryForReport)
            {
                return SeparatorTemplate ?? base.SelectTemplate(item, container);
            }
            return EntryForReportTemplate ?? base.SelectTemplate(item, container);
        }
    }

    public enum BackupOperation
    {
        Separator,
        BackupToClipboard,
        BackupToFile,
        BackupToDocuments,
        RestoreFromClipboard,
        RestoreFromFile,
        RestoreFromDocuments,
    }

    public class BackupOperationOption : OptionBaseItem
    {
        public BackupOperation Operation { get; set; }
    }

    public class SeparatorBackupOperationOption : BackupOperationOption { }

    public class BackupOperationOptionTemplateSelector : DataTemplateSelector
    {
        public DataTemplate? BackupOperationOptionTemplate { get; set; }
        public DataTemplate? SeparatorTemplate { get; set; }

        public override DataTemplate SelectTemplate(object item, DependencyObject container)
        {
            if (item is SeparatorBackupOperationOption)
            {
                return SeparatorTemplate ?? base.SelectTemplate(item, container);
            }
            return BackupOperationOptionTemplate ?? base.SelectTemplate(item, container);
        }
    }

    public class ThemeOption(Theme theme, bool isSelected = false)
    {
        public Theme Theme { get; } = theme;

        public bool IsSelected { get; } = isSelected;
    }

    public class HubSummary : NotifyPropertyChanged
    {
        private string? hub;
        public string? Hub
        {
            get => hub;
            set => Set(ref hub, value);
        }

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
    }

    public class Summary : NotifyPropertyChanged
    {
        private readonly ObservableCollection<HubSummary> hubSummaries = [];
        public ObservableCollection<HubSummary> HubSummaries => hubSummaries;

        private string? features;
        public string? Features
        {
            get => features;
            set => Set(ref features, value);
        }

        private string? shortFeatures;
        public string? ShortFeatures
        {
            get => shortFeatures;
            set => Set(ref shortFeatures, value);
        }

        private string? pages;
        public string? Pages
        {
            get => pages;
            set => Set(ref pages, value);
        }

        private string? shortPages;
        public string? ShortPages
        {
            get => shortPages;
            set => Set(ref shortPages, value);
        }

        private string? membership;
        public string? Membership
        {
            get => membership;
            set => Set(ref membership, value);
        }
    }

    public static class StringExtensions
    {
        public static string Capitalize(this string input)
        {
            if (string.IsNullOrEmpty(input))
            {
                return input;
            }

            char firstChar = char.ToUpper(input[0]);
            string restOfString = input.Length > 1 ? input[1..].ToLower() : string.Empty;

            return firstChar + restOfString;
        }
    }
}
