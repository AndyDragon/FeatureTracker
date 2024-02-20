using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.IO.IsolatedStorage;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using Windows.ApplicationModel.DataTransfer;
using Windows.UI;
using Windows.UI.Xaml.Media;

namespace Feature_Tracker
{
    public class MainViewModel : NotifyPropertyChanged
    {
        //private readonly HttpClient httpClient = new HttpClient();
        private bool loadingPages = false;

        public MainViewModel()
        {
            toggleSplitViewCommand = new Command(() => this.IsSplitViewPaneOpen = !this.IsSplitViewPaneOpen);
            addPageCommand = new Command(() =>
            {
                var page = new Page { Name = "new page" };
                Pages.Add(page);
                SelectedPage = page;
            });
            populateDefaultsCommand = new Command(PopulateDefaultPages);
            generateReportCommand = new Command(GenerateReport);
            backupCommand = new Command(BackupToClipboard);
            restoreCommand = new Command(() => _ = RestoreFromClipboard());
            Pages = new ObservableCollection<Page>();
            //SortedPages = new ObservableCollection<Page>();
            Pages.CollectionChanged += (sender, e) =>
            {
                //var sortedList = new List<Page>(Pages.OrderBy(page => page.Name));
                //var deletedList = new List<Page>(SortedPages);
                //for (var index = 0; index < sortedList.Count; index++)
                //{
                //    var oldIndex = SortedPages.IndexOf(sortedList[index]);
                //    if (oldIndex == -1)
                //    {
                //        SortedPages.Insert(index, sortedList[index]);
                //    }
                //    else if (oldIndex != index)
                //    {
                //        SortedPages.Move(oldIndex, index);
                //        deletedList.Remove(sortedList[index]);
                //    }
                //}
                //foreach (var page in deletedList)
                //{
                //    SortedPages.Remove(page);
                //}
                //if (Pages.Count != SortedPages.Count)
                //{
                    //SortedPages.Clear();
                    //SortedPages.Concat(sortedList);
                //    Debug.Print("Something fishy here...");
                //}
                if (!loadingPages)
                {
                    StorePages();
                }
            };
            loadingPages = true;
            LoadPages();
            loadingPages = false;
        }

        private void LoadPages()
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
                                    try
                                    {
                                        var loadedPages = JsonConvert.DeserializeObject<List<JsonPage>>(json);
                                        if (loadedPages != null)
                                        {
                                            foreach (var page in loadedPages)
                                            {
                                                Pages.Add(new Page(page));
                                            }
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        Debug.WriteLine(ex.Message);
                                        // TODO notify the user loading data failed.
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

        private void StorePages()
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
                        //var jsonPages = SortedPages.Select(page => page.ToJson());
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

        public ObservableCollection<Page> Pages { get; private set; }
        //public ObservableCollection<Page> SortedPages { get; private set; }

        private Page selectedPage = null;
        public Page SelectedPage
        {
            get => selectedPage;
            set => Set(ref selectedPage, value);
        }

        private bool isSplitViewPaneOpen = true;
        public bool IsSplitViewPaneOpen
        {
            get => isSplitViewPaneOpen;
            set => Set(ref isSplitViewPaneOpen, value);
        }

        private readonly ICommand toggleSplitViewCommand;
        public ICommand ToggleSplitViewCommand
        {
            get => toggleSplitViewCommand;
        }

        private readonly ICommand addPageCommand;
        public ICommand AddPageCommand
        {
            get => addPageCommand;
        }

        private readonly ICommand populateDefaultsCommand;
        public ICommand PopulateDefaultsCommand
        {
            get => populateDefaultsCommand;
        }

        private readonly ICommand generateReportCommand;
        public ICommand GenerateReportCommand
        {
            get => generateReportCommand;
        }

        private readonly ICommand backupCommand;
        public ICommand BackupCommand
        {
            get => backupCommand;
        }

        private readonly ICommand restoreCommand;
        public ICommand RestoreCommand
        {
            get => restoreCommand;
        }

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

            Pages.Clear();

            foreach (var pageName in singleFeaturePages)
            {
                Pages.Add(new Page { Name = pageName });
            }

            Pages.Add(new Page { Name = "papanoel", Count = 3 });
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
                builder.AppendFormat("Total features: {0} (counts as {1})", featuresCount, totalFeaturesCount);
            }
            else
            {
                builder.AppendFormat("Total features: {0}", featuresCount);
            }
            builder.AppendLine();
            builder.AppendLine();
            var pagesCount = GetPages();
            var totalPagesCount = GetTotalPages();
            if (pagesCount != totalPagesCount)
            {
                builder.AppendFormat("Total pages with features: {0} (counts as {1})", pagesCount, totalPagesCount);
            }
            else
            {
                builder.AppendFormat("Total pages with features: {0}", pagesCount);
            }
            builder.AppendLine();
            builder.AppendLine();
            //foreach (var page in SortedPages)
            foreach (var page in Pages)
            {
                if (page.Features.Count != 0)
                {
                    if (page.Count != 1)
                    {
                        builder.AppendFormat(
                            "Page: {0} - {1} (counts as {2})",
                            page.Name,
                            GetStringForCount(page.Features.Count, "feature"),
                            page.Count * page.Features.Count);
                    }
                    else
                    {
                        builder.AppendFormat(
                            "Page: {0} - {1}",
                            page.Name,
                            GetStringForCount(page.Features.Count, "feature"));
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
            //var jsonPages = SortedPages.Select(page => page.ToJson());
            var jsonPages = Pages.Select(page => page.ToJson());
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
                        loadingPages = true;
                        Pages.Clear();
                        foreach (var page in loadedPages)
                        {
                            Pages.Add(new Page(page));
                        }
                        loadingPages = false;
                        StorePages();
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
    }

    public class Page : MenuItem
    {
        //private static readonly SolidColorBrush BlackBrush = new SolidColorBrush(Colors.Black);
        private static readonly SolidColorBrush WhiteBrush = new SolidColorBrush(Colors.White);
        private static readonly SolidColorBrush CadetBlueBrush = new SolidColorBrush(Colors.CadetBlue);

        private readonly Func<int, string> GetSuffix = count => count != 1 ? "s" : "";

        public Page()
        {
            Features = new ObservableCollection<Feature>();
            Features.CollectionChanged += (sender, e) =>
            {
                Foreground = Features.Count == 0 ? WhiteBrush : CadetBlueBrush;
                AlternativeTitle = $"{Features.Count} Feature{GetSuffix(Features.Count)}";
            };
            Title = Name.ToUpper();
            Foreground = Features.Count == 0 ? WhiteBrush : CadetBlueBrush;
            AlternativeTitle = $"{Features.Count} Feature{GetSuffix(Features.Count)}";
            SubTitle = $"(counts as {Count})";
        }

        public Page(JsonPage page) : this()
        {
            Name = page.Name;
            Notes = page.Notes;
            Count = page.Count;
            foreach (var feature in page.Features)
            {
                Features.Add(new Feature(feature));
            }
        }

        public JsonPage ToJson()
        {
            return new JsonPage
            {
                Name = Name,
                Notes = Notes,
                Count = Count,
                Features = new List<JsonFeature>(Features.Select(feature => feature.ToJson()))
            };
        }

        public ObservableCollection<Feature> Features { get; private set; }

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
    }

    public class Feature : NotifyPropertyChanged
    {
        public Feature()
        {
        }

        public Feature(JsonFeature feature) : this()
        {
            Date = new DateTime(2001, 1, 1) + TimeSpan.FromMilliseconds(feature.Date * 1000);
            Raw = feature.Raw;
            Notes = feature.Notes;
        }

        public JsonFeature ToJson()
        {
            return new JsonFeature
            {
                Date = (Date - new DateTime(2001, 1, 1)).TotalMilliseconds / 1000,
                Raw = Raw,
                Notes = Notes,
            };
        }

        private DateTime date = DateTime.Now;
        public DateTime Date
        {
            get => date; 
            set => Set(ref date, value);
        }

        private bool raw = false;
        public bool Raw
        {
            get => raw; 
            set => Set(ref raw, value);
        }

        private string notes = "";
        public string Notes
        {
            get => notes; 
            set => Set(ref notes, value);
        }
    }

    public class JsonPage
    {
        [JsonProperty(PropertyName = "name")]
        public string Name { get; set; } = "";

        [JsonProperty(PropertyName = "notes")]
        public string Notes { get; set; } = "";

        [JsonProperty(PropertyName = "count")]
        public int Count { get; set; } = 1;

        [JsonProperty(PropertyName = "features", NullValueHandling = NullValueHandling.Ignore)]
        public IList<JsonFeature> Features { get; set; } = new List<JsonFeature>();
    }

    public class JsonFeature
    {
        [JsonProperty(PropertyName = "date")]
        public double Date { get; set; } = (DateTime.Now - new DateTime(2001, 1, 1)).TotalMilliseconds / 1000;

        [JsonProperty(PropertyName = "raw")]
        public bool Raw { get; set; } = false;

        [JsonProperty(PropertyName = "notes")]
        public string Notes { get; set; } = "";
    }
}
