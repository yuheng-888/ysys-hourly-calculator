using System.Collections.ObjectModel;
using System.Collections.Specialized;
using AutoSoundTimeV3.Models;

namespace AutoSoundTimeV3.Services;

public class TeamSettlementStore
{
    private const string FileName = "team_settlements.json";

    public ObservableCollection<SettlementEntry> Entries { get; }

    public TeamSettlementStore()
    {
        var loaded = StorageService.Load(FileName, new ObservableCollection<SettlementEntry>());
        Entries = loaded;
        Entries.CollectionChanged += OnCollectionChanged;
    }

    private void OnCollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        StorageService.Save(FileName, Entries);
    }

    public void Save() => StorageService.Save(FileName, Entries);
}
