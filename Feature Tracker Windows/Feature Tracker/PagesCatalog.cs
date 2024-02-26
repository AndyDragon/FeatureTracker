namespace FeatureTracker.Json
{
    public class PagesCatalog
    {
        public PageEntry[] Pages { get; set; } = [];
    }

    public class PageEntry
    {
        public string Name { get; set; } = string.Empty;

        public string PageName { get; set; } = string.Empty;
    }
}
