<?php

namespace App\Services\Ai\OpenAI\Image;

use App\Helpers\Classes\Helper;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CreateImageService
{
    private string $generateURL = 'https://api.openai.com/v1/images/generations';

    private string $model = 'gpt-image-1';

    private string $prompt = '';

    private string $size = '1024x1024';

    private string $quality = 'auto';

    private string $output_format = 'webp';

    public function generateForAi(): ?string
    {
        $requestData = $this->requestData();

        $httpClient = Http::timeout(10000)
            ->withHeaders([
                'Content-Type'  => 'application/json',
                'Authorization' => 'Bearer ' . Helper::setOpenAiKey(),
            ])->post($this->generateURL, $requestData);

        if ($httpClient->failed()) {
            return null;
        }

        if ($httpClient->json('created') && $httpClient->json('data')) {
            $image = Arr::first($httpClient->json('data'));

            if (isset($image['b64_json'])) {
                return $image['b64_json'];
            }
        }

        return null;
    }

    public function generate(): array
    {
        $requestData = $this->requestData();

        $httpClient = Http::timeout(10000)
            ->withHeaders([
                'Content-Type'  => 'application/json',
                'Authorization' => 'Bearer ' . Helper::setOpenAiKey(),
            ])->post($this->generateURL, $requestData);

        if ($httpClient->failed()) {
            return [
                'status'  => false,
                'message' => $httpClient->json('error.message'),
            ];
        }

        if ($httpClient->json('created') && $httpClient->json('data')) {
            $data = $httpClient->json('data');

            $image = Arr::first($data);

            if (isset($image['b64_json'])) {
                $base64Image = $image['b64_json'];

                $imageName = Str::uuid()->toString() . '.' . $this->getOutputFormat();

                Storage::disk('uploads')->put($imageName, base64_decode($base64Image));

                return [
                    'status'  => true,
                    'message' => 'Image generated successfully',
                    'path'    => '/uploads/' . $imageName,
                ];
            }
        }

        return [
            'status'  => false,
            'message' => 'Image generation failed. Please try again later.',
        ];
    }

    public function requestData(): array
    {
        return [
            'model'           => $this->getModel(),
            'prompt'          => $this->getPrompt(),
            'size'            => $this->getSize(),
            'n'               => 1,
            //            'response_format' => 'b64_json',
            'output_format'   => $this->getOutputFormat(),
            'quality'         => $this->getQuality(),
        ];
    }

    public function setModel(string $model): CreateImageService
    {
        $this->model = $model;

        return $this;
    }

    public function getModel(): string
    {
        return $this->model;
    }

    public function setPrompt(string $prompt): CreateImageService
    {
        $this->prompt = $prompt;

        return $this;
    }

    public function getPrompt(): string
    {
        return $this->prompt;
    }

    public function setSize(string $size): CreateImageService
    {
        $this->size = $size;

        return $this;
    }

    public function getSize(): string
    {
        return $this->size;
    }

    public function setQuality(string $quality): CreateImageService
    {
        $this->quality = $quality;

        return $this;
    }

    public function getQuality(): string
    {
        return $this->quality;
    }

    public function setOutputFormat(string $output_format): CreateImageService
    {
        $this->output_format = $output_format;

        return $this;
    }

    public function getOutputFormat(): string
    {
        return $this->output_format;
    }
}
