using System;
using System.Collections.ObjectModel;
using System.Runtime.CompilerServices;

namespace FeatureTracker
{
    public class NotifyDataChangedEventArgs : EventArgs
    {
        public NotifyDataChangedEventArgs(string propertyName) 
        { 
            PropertyName = propertyName;
        }

        public string PropertyName { get; private set; }
    }

    public delegate void NotifyDataChangedEventHandler(object sender, NotifyDataChangedEventArgs e);

    public interface IDataManager
    {
        void AddModel(Model model);

        void AddModelCollection<T> (ObservableCollection<T> collection) where T : Model;

        void RemoveModel(Model model);

        void RemoveModelCollection<T>(ObservableCollection<T> collection) where T : Model;
    }

    public abstract class Model : NotifyPropertyChanged
    {
        public abstract string[] ModelProperties { get; }

        public abstract string[] ModelCollectionProperties { get; }
        
        public abstract IDataManager DataManager { get; set; }

        public void OnDataChanged([CallerMemberName] string propertyName = null)
        {
            DataChanged?.Invoke(this, new NotifyDataChangedEventArgs(propertyName));
        }

        public event NotifyDataChangedEventHandler DataChanged;
    }
}
