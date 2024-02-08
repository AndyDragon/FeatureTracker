using System.Collections.Generic;
using System.ComponentModel;
using Avalonia.Controls;
using Microsoft.Data.Sqlite;

namespace FeatureTracker;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        DataContext = new DatabaseDataContext();
    }
}

public class DatabaseDataContext : INotifyPropertyChanged
{
    private readonly SqliteConnection connection;

    public DatabaseDataContext()
    {
        connection = new SqliteConnection("Data Source=features.db");
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText =
            @"
                DROP TABLE IF EXISTS pages;
                DROP TABLE IF EXISTS platforms;
                DROP TABLE IF EXISTS features;

                CREATE TABLE IF NOT EXISTS pages (
                    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    notes TEXT NOT NULL,
                    count INTEGER NOT NULL,
                    UNIQUE (name)
                );

                CREATE TABLE IF NOT EXISTS platforms (
                    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    notes TEXT NOT NULL,
                    UNIQUE (name)
                );

                CREATE TABLE IF NOT EXISTS features (
                    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                    page_id INTEGER NOT NULL,
                    platform_id INTEGER NOT NULL,
                    date TEXT NOT NULL,
                    notes TEXT NOT NULL,
                    FOREIGN KEY (page_id) REFERENCES pages (id),
                    FOREIGN KEY (platform_id) REFERENCES platforms (id)
                );

                INSERT INTO pages (name, notes, count)
                VALUES
                    ('abandoned', '', 1),
                    ('abstract', '', 1),
                    ('africa', '', 1),
                    ('ai', '', 1),
                    ('allblack', '', 1),
                    ('allnature', '', 1),
                    ('allsports', '', 1),
                    ('alltrees', '', 1),
                    ('allwhite', '', 1),
                    ('architecture', '', 1),
                    ('artgallery', '', 1),
                    ('asia', '', 1),
                    ('australia', '', 1),
                    ('beaches', '', 1),
                    ('birds', '', 1),
                    ('blue', '', 1),
                    ('bnw', '', 1),
                    ('books', '', 1),
                    ('bridges', '', 1),
                    ('butterflies', '', 1),
                    ('canada', '', 1),
                    ('cats', '', 1),
                    ('china', '', 1),
                    ('cityscape', '', 1),
                    ('cocktails', '', 1),
                    ('coffee', '', 1),
                    ('collage', '', 1),
                    ('colorsplash', '', 1),
                    ('colours', '', 1),
                    ('community_member', '', 1),
                    ('country', '', 1),
                    ('cuteness', '', 1),
                    ('default', '', 1),
                    ('depthoffield', '', 1),
                    ('drone', '', 1),
                    ('drops', '', 1),
                    ('edit', '', 1),
                    ('europe', '', 1),
                    ('fishing', '', 1),
                    ('flatlays', '', 1),
                    ('flowers', '', 1),
                    ('foggy', '', 1),
                    ('france', '', 1),
                    ('gardening', '', 1),
                    ('germany', '', 1),
                    ('herpetology', '', 1),
                    ('hikes', '', 1),
                    ('homestyle', '', 1),
                    ('horses', '', 1),
                    ('india', '', 1),
                    ('insects', '', 1),
                    ('ireland', '', 1),
                    ('kitchen', '', 1),
                    ('landscape', '', 1),
                    ('lighthouses', '', 1),
                    ('longexposure', '', 1),
                    ('macro', '', 1),
                    ('minimal', '', 1),
                    ('mobile', '', 1),
                    ('moody', '', 1),
                    ('mountains', '', 1),
                    ('nightshots', '', 1),
                    ('nordic', '', 1),
                    ('numbers', '', 1),
                    ('oceanlife', '', 1),
                    ('people', '', 1),
                    ('pets', '', 1),
                    ('potd', '', 1),
                    ('reflection', '', 1),
                    ('seasons', '', 1),
                    ('silhouette', '', 1),
                    ('skies', '', 1),
                    ('street', '', 1),
                    ('surreal', '', 1),
                    ('symmetry', '', 1),
                    ('tattoos', '', 1),
                    ('thailand', '', 1),
                    ('toys', '', 1),
                    ('transports', '', 1),
                    ('uae', '', 1),
                    ('uk', '', 1),
                    ('usa', '', 1),
                    ('waters', '', 1),
                    ('weddings', '', 1),
                    ('wildlife', '', 1),
                    ('world', '', 1),
                    ('writings', '', 1),
                    ('papanoel', 'Counts for three', 3)
                ON CONFLICT DO NOTHING;

                INSERT INTO platforms (name, notes)
                VALUES
                    ('VERO snap', ''),
                    ('VERO raw', ''),
                    ('Instagram snap', '')
                ON CONFLICT DO NOTHING;
            ";
        command.ExecuteNonQuery();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private bool pagesLoaded = false;
    private readonly List<Page> pages = new();
    public List<Page> Pages
    {
        get
        {
            if (!pagesLoaded)
            {
                var command = connection.CreateCommand();
                command.CommandText =
                    @"
                        SELECT *
                        FROM pages
                    ";
                using var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    var page = new Page(reader.GetInt32(0))
                    {
                        Name = reader.GetString(1)
                    };
                    pages.Add(page);
                }
                pagesLoaded = true;
            }
            return pages;
        }
    }

    private bool featuresLoaded = false;
    private readonly List<Feature> features = new();
    public List<Feature> Features
    {
        get
        {
            if (!featuresLoaded)
            {
                var command = connection.CreateCommand();
                command.CommandText =
                    @"
                        SELECT *
                        FROM feature
                    ";
                using var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    var feature = new Feature(reader.GetInt32(0))
                    {
                        Page = reader.GetString(1)
                    };
                    features.Add(feature);
                }
                featuresLoaded = true;
            }
            return features;
        }
    }

    public string FeatureCount
    {
        get
        {
            return Features.Count.ToString();
        }
    }
}

public class Page : INotifyPropertyChanged
{
    public Page(int id)
    {
        Id = id;
    }

    public int Id { get; private set; }

    public event PropertyChangedEventHandler? PropertyChanged;

    private string? name;
    public string Name
    {
        get
        {
            return name ?? "";
        }
        set
        {
            if (value != name)
            {
                name = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Name)));
            }
        }
    }
}

public class Feature : INotifyPropertyChanged
{
    public Feature(int id)
    {
        Id = id;
    }

    public int Id { get; private set; }

    public event PropertyChangedEventHandler? PropertyChanged;

    private string? page;
    public string Page
    {
        get
        {
            return page ?? "";
        }
        set
        {
            if (value != page)
            {
                page = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Page)));
            }
        }
    }
}
