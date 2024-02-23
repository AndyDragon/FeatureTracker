using FontAwesome.UWP;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Diagnostics;
using System.IO;
using System.IO.IsolatedStorage;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using Windows.ApplicationModel.DataTransfer;
using Windows.Storage;
using Windows.UI;
using Windows.UI.Xaml.Media;

namespace FeatureTracker
{
    public class MainViewModel : NotifyPropertyChanged, IDataManager
    {
        private int operationCount = 0;

        private readonly ApplicationDataContainer SettingsContainer = ApplicationData.Current.RoamingSettings;

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
            sortByNameCommand = new Command(() =>
            {
                pageSort = PageComparer.NameComparer;
                SettingsContainer.Values["PageSort"] = (int)PageComparer.CompareMode.Name;
                RefreshPages();
            });
            sortByCountCommand = new Command(() =>
            {
                pageSort = PageComparer.CountComparer;
                SettingsContainer.Values["PageSort"] = (int)PageComparer.CompareMode.Count;
                RefreshPages();
            });
            sortByFeaturesCommand = new Command(() =>
            {
                pageSort = PageComparer.FeaturesComparer;
                SettingsContainer.Values["PageSort"] = (int)PageComparer.CompareMode.Features;
                RefreshPages();
            });
            refreshPagesCommand = new Command(() =>
            {
                RefreshPages();
            });
            populateDefaultsCommand = new Command(PopulateDefaultPages);
            generateReportCommand = new Command(GenerateReport);
            backupCommand = new Command(BackupToClipboard);
            restoreCommand = new Command(() => _ = RestoreFromClipboard());
            closePageCommand = new Command(() => SelectedPage = null);
            deletePageCommand = new Command(() =>
            {
                var page = SelectedPage;
                SelectedPage = null;
                Pages.Remove(page);
                RemoveModel(page);
            });
            Pages = new SortableModelCollection<Page>();

            if (SettingsContainer.Values.ContainsKey("PageSort"))
            {
                switch ((PageComparer.CompareMode)SettingsContainer.Values["PageSort"])
                {
                    case PageComparer.CompareMode.Count:
                        pageSort = PageComparer.CountComparer;
                        break;
                    case PageComparer.CompareMode.Features:
                        pageSort = PageComparer.FeaturesComparer;
                        break;
                    default:
                        pageSort = PageComparer.NameComparer;
                        break;
                }
            }

            AddModelCollection(Pages);
            StartOperation();
            LoadPages();
            Pages.SortBy(pageSort);
            StopOperation();
        }

        private void LoadPages()
        {
            try
            {
                using (var isoStore =
                IsolatedStorageFile.GetStore(
                    IsolatedStorageScope.User |
                    IsolatedStorageScope.Assembly |
                    IsolatedStorageScope.Roaming,
                    null,
                    null))
                {
                    if (isoStore != null)
                    {
                        using (var stream = isoStore.OpenFile("PagesStore", FileMode.Open))
                        {
                            if (stream != null)
                            {
                                using (var streamReader = new StreamReader(stream))
                                {
                                    var json = streamReader.ReadToEnd();
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
                                        }
                                    }
                                    streamReader.Close();
                                }
                                stream.Close();
                            }
                        }
                        isoStore.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
                // TODO notify the user loading data failed.
            }
        }

        private void StorePages()
        {
            try
            {
                using (var isoStore =
                    IsolatedStorageFile.GetStore(
                        IsolatedStorageScope.User |
                        IsolatedStorageScope.Assembly |
                        IsolatedStorageScope.Roaming,
                        null,
                        null))
                {
                    if (isoStore != null)
                    {
                        using (var stream = isoStore.OpenFile("PagesStore", FileMode.Create))
                        {
                            var jsonPages = Pages.Select(page => page.ToJson());
                            var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
                            using (var streamWriter = new StreamWriter(stream))
                            {
                                streamWriter.Write(json);
                                streamWriter.Flush();
                            }
                            stream.Close();
                        }
                        isoStore.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
                // TODO notify the user saving data failed.
            }
        }

        private void RefreshPages()
        {
            StartOperation();
            var oldSelectedPage = SelectedPage;
            SelectedPage = null;
            Pages.SortBy(pageSort);
            StopOperation();
            SelectedPage = oldSelectedPage;
            OnPropertyChanged(nameof(SortedByNameCheck));
            OnPropertyChanged(nameof(SortedByCountCheck));
            OnPropertyChanged(nameof(SortedByFeaturesCheck));
        }

        public SortableModelCollection<Page> Pages { get; private set; }

        private PageComparer pageSort = PageComparer.NameComparer;

        private Page selectedPage = null;
        public Page SelectedPage
        {
            get => selectedPage;
            set
            {
                if (Set(ref selectedPage, value))
                {

                }
            }
        }

        private bool isSplitViewPaneOpen = true;
        public bool IsSplitViewPaneOpen
        {
            get => isSplitViewPaneOpen;
            set => Set(ref isSplitViewPaneOpen, value);
        }

        private readonly ICommand toggleSplitViewCommand;
        public ICommand ToggleSplitViewCommand => toggleSplitViewCommand;

        private readonly ICommand addPageCommand;
        public ICommand AddPageCommand => addPageCommand;

        private readonly ICommand sortByNameCommand;
        public ICommand SortByNameCommand => sortByNameCommand;

        private readonly ICommand sortByCountCommand;
        public ICommand SortByCountCommand => sortByCountCommand;

        private readonly ICommand sortByFeaturesCommand;
        public ICommand SortByFeaturesCommand => sortByFeaturesCommand;

        private readonly ICommand refreshPagesCommand;
        public ICommand RefreshPagesCommand => refreshPagesCommand;

        private readonly ICommand populateDefaultsCommand;
        public ICommand PopulateDefaultsCommand => populateDefaultsCommand;

        private readonly ICommand generateReportCommand;
        public ICommand GenerateReportCommand => generateReportCommand;

        private readonly ICommand backupCommand;
        public ICommand BackupCommand => backupCommand;

        private readonly ICommand restoreCommand;
        public ICommand RestoreCommand => restoreCommand;

        private readonly ICommand closePageCommand;
        public ICommand ClosePageCommand => closePageCommand;

        private readonly ICommand deletePageCommand;
        public ICommand DeletePageCommand => deletePageCommand;

        public FontAwesomeIcon SortedByNameCheck => pageSort == PageComparer.NameComparer ? FontAwesomeIcon.Check : FontAwesomeIcon.None;

        public FontAwesomeIcon SortedByCountCheck => pageSort == PageComparer.CountComparer ? FontAwesomeIcon.Check : FontAwesomeIcon.None;

        public FontAwesomeIcon SortedByFeaturesCheck => pageSort == PageComparer.FeaturesComparer ? FontAwesomeIcon.Check : FontAwesomeIcon.None;

        private void PopulateDefaultPages()
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

        private string GetStringForCount(int count, string baseString, string pluralString = null)
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

        private void GenerateReport()
        {
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
                    if (page.Count != 1)
                    {
                        builder.AppendLine(
                            $"Page: {page.Name.ToUpper()} - {GetStringForCount(page.Features.Count, "feature")} (counts as {page.Count * page.Features.Count})");
                    }
                    else
                    {
                        builder.AppendLine(
                            $"Page: {page.Name.ToUpper()} - {GetStringForCount(page.Features.Count, "feature")}");
                    }
                    foreach (var feature in page.Features.OrderBy(feature => feature, FeatureComparer.DateComparer))
                    {
                        var hub = feature.Raw ? "RAW" : "Snap";
                        builder.AppendLine($"\tFeature: {feature.Date.ToLocalTime():D} on {hub}:");
                        builder.AppendLine($"\t\t{feature.Notes}");
                    }
                }
            }

            SetClipboard(builder.ToString());
        }

        private void SetClipboard(string text)
        {
            // Set the clipboard.
            var package = new DataPackage
            {
                RequestedOperation = DataPackageOperation.Copy
            };
            package.SetText(text);
            Clipboard.SetContent(package);

        }

        private void BackupToClipboard()
        {
            var jsonPages = Pages.OrderBy(page => page.Name).Select(page => page.ToJson());
            var json = JsonConvert.SerializeObject(jsonPages, Formatting.Indented);
            SetClipboard(json);
        }

        private async Task RestoreFromClipboard()
        {
            DataPackageView dataPackageView = Clipboard.GetContent();
            if (dataPackageView.Contains(StandardDataFormats.Text))
            {
                string json = await dataPackageView.GetTextAsync();
                try
                {
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
                        // TODO notify the user the restore succeeded...
                    }
                    else
                    {
                        // TODO notify the user the restore failed...
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine(ex.Message);
                    // TODO notify the user the restore failed...
                }
            }
        }

        private void OnModelChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
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
        }

        public void RemoveModel(Model model)
        {
            model.DataManager = null;
            model.PropertyChanged -= OnModelChanged;
        }

        private void OnModelCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            // TODO trigger debouncer to save data...
            if (operationCount == 0)
            {
                Debug.WriteLine("Saving data from collection changed...");
                StorePages();
            }
        }

        public void AddModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged += OnModelCollectionChanged;
        }

        public void RemoveModelCollection<T>(ObservableCollection<T> collection) where T : Model
        {
            collection.CollectionChanged -= OnModelCollectionChanged;
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
    }

    public class Page : EditableModel
    {
        private static readonly SolidColorBrush WhiteBrush = new SolidColorBrush(Colors.White);
        private static readonly SolidColorBrush CadetBlueBrush = new SolidColorBrush(Colors.CadetBlue);

        private readonly Func<int, string> GetSuffix = count => count != 1 ? "s" : "";

        public Page()
        {
            refreshFeaturesCommand = new Command(() =>
            {
                RefreshFeatures();
            });
            addFeatureCommand = new Command(() =>
            {
                var feature = new Feature() { Date = DateTime.Now };
                DataManager.AddModel(feature);
                Features.Add(feature);
                SelectedFeature = feature;
            });
            closeFeatureCommand = new Command(() => SelectedFeature = null);
            deleteFeatureCommand = new Command(() =>
            {
                var feature = SelectedFeature;
                SelectedFeature = null;
                Features.Remove(feature);
                DataManager.RemoveModel(feature);
            });
            Features = new SortableModelCollection<Feature>();
            Features.CollectionChanged += (sender, e) =>
            {
                Foreground = Features.Count == 0 ? WhiteBrush : CadetBlueBrush;
                AlternativeTitle = $"{Features.Count} Feature{GetSuffix(Features.Count)}";
                OnPropertyChanged("FeaturesCount");
            };
            Title = Name.ToUpper();
            Foreground = Features.Count == 0 ? WhiteBrush : CadetBlueBrush;
            AlternativeTitle = $"{Features.Count} Feature{GetSuffix(Features.Count)}";
            SubTitle = $"(counts as {Count})";
            EditorPageType = typeof(PageEditor);
        }

        public Page(JsonPage jsonPage) : this()
        {
            Id = jsonPage.Id;
            Name = jsonPage.Name;
            Notes = jsonPage.Notes;
            Count = jsonPage.Count;
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
                Features = new List<JsonFeature>(Features.Select(feature => feature.ToJson()))
            };
        }

        public SortableModelCollection<Feature> Features { get; private set; }

        private void RefreshFeatures()
        {
            DataManager.StartOperation();
            var oldSelectedFeature = SelectedFeature;
            SelectedFeature = null;
            Features.SortBy(FeatureComparer.DateComparer);
            DataManager.StopOperation();
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

        private Feature selectedFeature = null;
        public Feature SelectedFeature
        {
            get => selectedFeature;
            set
            {
                if (Set(ref selectedFeature, value))
                {

                }
            }
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
                    SubTitle = $"(counts as {Count})";
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

        public override string[] ModelProperties => new[] { nameof(Name), nameof(Notes), nameof(Count) };

        public override string[] ModelCollectionProperties => new[] { nameof(Features) };

        private IDataManager dataManager;
        public override IDataManager DataManager
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
        private static readonly SolidColorBrush WhiteBrush = new SolidColorBrush(Colors.White);

        public Feature()
        {
            Id = Guid.NewGuid();
            Title = Date.ToString("D");
            Foreground = WhiteBrush;
            AlternativeTitle = Raw ? "RAW" : "";
            SubTitle = Notes;
            EditorPageType = typeof(FeatureEditor);
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

        public override string[] ModelProperties => new[] { nameof(Date), nameof(Notes), nameof(Raw) };

        public override string[] ModelCollectionProperties => new string[] { };

        public override IDataManager DataManager { get; set; }
    }

    public class JsonPage
    {
        [JsonProperty(PropertyName = "count")]
        public int Count { get; set; } = 1;

        [JsonProperty(PropertyName = "features", NullValueHandling = NullValueHandling.Ignore)]
        public IList<JsonFeature> Features { get; set; } = new List<JsonFeature>();

        [JsonProperty(PropertyName = "id"), JsonConverter(typeof(UppercaseGuidConverter))]
        public Guid Id { get; set; } = Guid.NewGuid();

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
            return new Guid((string)reader.Value);
        }
    }
}
