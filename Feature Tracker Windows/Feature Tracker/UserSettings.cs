using System.Diagnostics;
using System.IO;
using Newtonsoft.Json;

namespace FeatureTracker
{
    internal class UserSettings
    {
        private static dynamic? cachedStore = null;

        private static void LoadStore()
        {
            if (cachedStore == null)
            {
                var userSettingsPath = MainViewModel.GetUserSettingsPath();
                if (File.Exists(userSettingsPath))
                {
                    var json = File.ReadAllText(userSettingsPath);
                    cachedStore = JsonConvert.DeserializeObject(json);
                }
            }
            cachedStore ??= new Dictionary<string, object>();
        }

        private static void SaveStore()
        {
            var userSettingsPath = MainViewModel.GetUserSettingsPath();
            var json = JsonConvert.SerializeObject(cachedStore);
            File.WriteAllText(userSettingsPath, json);
        }

        internal static int? GetInt(string key, int? defaultValue = null)
        {
            try
            {
                LoadStore();
                if (cachedStore?.ContainsKey(key))
                {
                    return cachedStore?[key];
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("Failed for load the user settings: " + ex.Message);
            }
            return defaultValue;
        }

        internal static string? GetString(string key, string? defaultValue = null)
        {
            try
            {
                LoadStore();
                if (cachedStore?.ContainsKey(key))
                {
                    return cachedStore?[key];
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("Failed for load the user settings: " + ex.Message);
            }
            return defaultValue;
        }

        internal static void StoreInt(string key, int value)
        {
            try
            {
                LoadStore();
                if (cachedStore != null)
                {
                    cachedStore[key] = value;
                }
                SaveStore();
            }
            catch (Exception ex)
            {
                Debug.WriteLine("Failed for load the user settings: " + ex.Message);
                throw;
            }
        }

        internal static void StoreString(string key, string value)
        {
            try
            {
                LoadStore();
                if (cachedStore != null)
                {
                    cachedStore[key] = value;
                }
                SaveStore();
            }
            catch (Exception ex)
            {
                Debug.WriteLine("Failed for load the user settings: " + ex.Message);
                throw;
            }
        }
    }

    internal class UserSettingsStore
    {
        [JsonProperty(PropertyName = "values")]
        public IDictionary<string, object>? Values { get; set; }
    }
}
