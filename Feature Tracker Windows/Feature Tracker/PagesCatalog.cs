using System;

namespace Feature_Tracker.Json
{
    public class PagesCatalog
    {
        public PagesCatalog()
        {
            Pages = Array.Empty<PageEntry>();
        }

        public PageEntry[] Pages { get; set; }
    }

    public class PageEntry
    {
        public PageEntry()
        {
            Name = string.Empty;
        }

        public string Name { get; set; }

        public string PageName { get; set; }
    }
}
