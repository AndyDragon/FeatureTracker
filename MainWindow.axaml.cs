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

        using var connection = new SqliteConnection("Data Source=features.db");
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText =
            @"
                --DROP TABLE IF EXISTS pages;
                --DROP TABLE IF EXISTS platforms;
                --DROP TABLE IF EXISTS features;

                CREATE TABLE IF NOT EXISTS pages (
                    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    notes TEXT NOT NULL,
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
                    FOREIGN KEY (page_id) REFERENCES pages (id),
                    FOREIGN KEY (platform_id) REFERENCES platforms (id)
                );

                INSERT INTO pages (name, notes)
                VALUES
                    ('abandoned', ''),
                    ('abstract', ''),
                    ('africa', ''),
                    ('ai', ''),
                    ('allblack', ''),
                    ('allnature', ''),
                    ('allsports', ''),
                    ('alltrees', ''),
                    ('allwhite', ''),
                    ('architecture', ''),
                    ('artgallery', ''),
                    ('asia', ''),
                    ('australia', ''),
                    ('beaches', ''),
                    ('birds', ''),
                    ('blue', ''),
                    ('bnw', ''),
                    ('books', ''),
                    ('bridges', ''),
                    ('butterflies', ''),
                    ('canada', ''),
                    ('cats', ''),
                    ('china', ''),
                    ('cityscape', ''),
                    ('cocktails', ''),
                    ('coffee', ''),
                    ('collage', ''),
                    ('colorsplash', ''),
                    ('colours', ''),
                    ('community_member', ''),
                    ('country', ''),
                    ('cuteness', ''),
                    ('default', ''),
                    ('depthoffield', ''),
                    ('drone', ''),
                    ('drops', ''),
                    ('edit', ''),
                    ('europe', ''),
                    ('fishing', ''),
                    ('flatlays', ''),
                    ('flowers', ''),
                    ('foggy', ''),
                    ('france', ''),
                    ('gardening', ''),
                    ('germany', ''),
                    ('herpetology', ''),
                    ('hikes', ''),
                    ('homestyle', ''),
                    ('horses', ''),
                    ('india', ''),
                    ('insects', ''),
                    ('ireland', ''),
                    ('kitchen', ''),
                    ('landscape', ''),
                    ('lighthouses', ''),
                    ('longexposure', ''),
                    ('macro', ''),
                    ('minimal', ''),
                    ('mobile', ''),
                    ('moody', ''),
                    ('mountains', ''),
                    ('nightshots', ''),
                    ('nordic', ''),
                    ('numbers', ''),
                    ('oceanlife', ''),
                    ('people', ''),
                    ('pets', ''),
                    ('potd', ''),
                    ('reflection', ''),
                    ('seasons', ''),
                    ('silhouette', ''),
                    ('skies', ''),
                    ('street', ''),
                    ('surreal', ''),
                    ('symmetry', ''),
                    ('tattoos', ''),
                    ('thailand', ''),
                    ('toys', ''),
                    ('transports', ''),
                    ('uae', ''),
                    ('uk', ''),
                    ('usa', ''),
                    ('waters', ''),
                    ('weddings', ''),
                    ('wildlife', ''),
                    ('world', ''),
                    ('writings', ''),
                    ('papanoel', 'Counts for three')
                ON CONFLICT DO NOTHING;

                INSERT INTO platforms (name, notes)
                VALUES
                    ('VERO snap', ''),
                    ('VERO raw', ''),
                    ('Instagram snap', '')
                ON CONFLICT DO NOTHING;
            ";
        command.ExecuteNonQuery();

        DataContext = new DatabaseDataContext(connection);
    }
}

public class DatabaseDataContext : INotifyPropertyChanged
{
    private readonly SqliteConnection connection;

    public DatabaseDataContext(SqliteConnection connection)
    {
        this.connection = connection;
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
