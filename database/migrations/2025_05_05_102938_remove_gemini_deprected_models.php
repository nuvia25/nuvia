<?php

use App\Helpers\Classes\EntityRemover;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $modelsToBeRemoved = ['gemini-pro-vision', 'gemini-pro', 'gemini-1.5-pro-latest'];

        foreach ($modelsToBeRemoved as $model) {
            EntityRemover::removeEntity($model);
        }

        $default = setting('gemini_default_model');
        if (in_array($default, $modelsToBeRemoved, true)) {
            $newDefault = 'gemini-1.5-flash';
            setting([
                'gemini_default_model' => $newDefault,
            ])->save();
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
