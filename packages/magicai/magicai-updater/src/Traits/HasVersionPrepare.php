<?php

namespace MagicAI\Updater\Traits;

trait HasVersionPrepare
{
    public bool|string $currentMagicAIVersion = '';

    public string $nextVersion = '';

    public string $latestVersion = '';

    public string $versionZipFile = '';

    public function prepareVersion(): array
    {
        $lastVersion = $this->versionRequest()->json() ?: [];

        $currentMagicAIVersion = floatval($this->currentMagicAIVersion());

        $description = $lastVersion['description'] ?? [];

        $versions = $this->versions($description);

        $this->nextVersion = $this->setNextVersion($versions, $currentMagicAIVersion);

        $this->latestVersion = $this->setLatestVersion($versions, $currentMagicAIVersion);

        $this->setZipFile();

        if (version_compare($this->nextVersion, $this->currentMagicAIVersion(), '>')) {
            $lastVersion['update'] = 'yes'; // Trigger the new version available.
            $lastVersion['version'] = $this->nextVersion;
            $lastVersion['latest_version'] = format_double($this->latestVersion);
            $lastVersion['version_format'] = format_double($this->nextVersion);
            $lastVersion['archive'] = $this->versionZipFile;
            $lastVersion['current_version'] = format_double($currentMagicAIVersion);
        }

        return $lastVersion;
    }

    public function setZipFile(): string
    {
        $this->versionZipFile = 'magicai_' . $this->nextVersion . '.zip';

        return $this->versionZipFile;
    }

    public function setNextVersion(array $versions, string $currentMagicAIVersion): string
    {
        sort($versions, SORT_NATURAL); // 5.3, 5.31, 5.4, 5.41

        foreach ($versions as $version) {
            if ($version > $currentMagicAIVersion) {
                return number_format($version, 2, '.');
            }
        }

        return '';
    }

    public function setLatestVersion(array $versions, string $currentMagicAIVersion): string
    {
        sort($versions, SORT_NATURAL); // 5.3, 5.31, 5.4, 5.41

        $latestVersion = end($versions);

        if ($latestVersion > $currentMagicAIVersion) {
            return number_format($latestVersion, 2, '.');
        }

        return '';
    }

    public function versions(array $array = []): array
    {
        $versionList = array_map(function ($key) {
            return trim(explode('-', $key)[0]);
        }, array_keys($array));

        $formatted = array_map(function ($version) {
            $parts = explode('.', $version);

            // Eğer 3 parçalıysa: major.minor.patch => "8.70"
            if (count($parts) === 3) {
                return (float) ($parts[0] . '.' . $parts[1] . $parts[2]);
            }

            // Eğer 2 parçalıysa: major.minor => "7.20"
            if (count($parts) === 2) {
                return (float) ($parts[0] . '.' . $parts[1]);
            }

            // Tek parçalıysa => "7"
            return (float) ($parts[0]);
        }, $versionList);

        return $formatted;
    }
}
