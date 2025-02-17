using System.Reflection;

namespace FeatureTracker
{
    public class AboutViewModel
    {
        public string Title => "About Feature Tracker";
        public string AppTitle => "Feature Tracker";
        public string Version => $"Version {Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---"}";
        public string Author => $"AndyDragon Software";
        public string Copyright => $"Copyright \u00a9 2024-{DateTime.Now.Year}";
        public string Rights => $"All rights reserved.";
    }
}
